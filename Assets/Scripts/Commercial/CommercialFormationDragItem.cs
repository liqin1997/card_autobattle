using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform), typeof(CanvasGroup))]
    public sealed class CommercialFormationDragItem : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        [SerializeField] private float followSharpness = 20f;
        [SerializeField] private float rotationSharpness = 15f;
        [SerializeField] private float rotationPerPixel = .18f;
        [SerializeField] private float maxDragRotation = 18f;
        [SerializeField] private float dragScale = 1.10f;

        private CommercialPrototypeController controller;
        private RectTransform sourceRect;
        private CanvasGroup sourceGroup;
        private RectTransform ghost;
        private CanvasGroup ghostGroup;
        private Vector2 targetLocal;
        private Vector2 previousLocal;
        private string libraryCardId;
        private int formationIndex = -1;
        private bool dragging;

        public int FormationIndex => formationIndex;
        public string LibraryCardId => libraryCardId;

        private void Awake()
        {
            sourceRect = (RectTransform)transform;
            sourceGroup = GetComponent<CanvasGroup>();
        }

        public void Configure(CommercialPrototypeController owner, string cardId, int sourceFormationIndex)
        {
            controller = owner;
            libraryCardId = cardId;
            formationIndex = sourceFormationIndex;
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            if (!controller || !controller.CanBeginFormationDrag(this)) return;
            dragging = true;
            sourceGroup.alpha = .38f;
            sourceGroup.blocksRaycasts = false;
            CreateGhost();
            UpdateTarget(eventData.position, true);
            controller.BeginFormationDrag(this);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (!dragging) return;
            UpdateTarget(eventData.position, false);
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (!dragging) return;
            dragging = false;
            sourceGroup.alpha = 1f;
            sourceGroup.blocksRaycasts = true;
            controller.EndFormationDrag(this, eventData.position);
            if (ghost) Destroy(ghost.gameObject);
            ghost = null;
            ghostGroup = null;
        }

        private void LateUpdate()
        {
            if (!dragging || !ghost) return;
            var t = 1f - Mathf.Exp(-followSharpness * Time.unscaledDeltaTime);
            var current = ghost.anchoredPosition;
            var next = Vector2.Lerp(current, targetLocal, t);
            ghost.anchoredPosition = next;

            var lag = targetLocal.x - next.x;
            var targetRotation = Mathf.Clamp(-lag * rotationPerPixel, -maxDragRotation, maxDragRotation);
            var rotationT = 1f - Mathf.Exp(-rotationSharpness * Time.unscaledDeltaTime);
            ghost.localRotation = Quaternion.Euler(0f, 0f,
                Mathf.LerpAngle(ghost.localEulerAngles.z, targetRotation, rotationT));
            ghost.localScale = Vector3.Lerp(ghost.localScale, Vector3.one * dragScale, t);
            previousLocal = next;
        }

        private void CreateGhost()
        {
            var layer = controller.FormationDragLayer;
            if (!layer) return;
            var clone = Instantiate(gameObject, layer, false);
            clone.name = $"DragGhost_{gameObject.name}";
            var drag = clone.GetComponent<CommercialFormationDragItem>();
            if (drag) drag.enabled = false;
            var button = clone.GetComponent<Button>();
            if (button) button.enabled = false;
            ghostGroup = clone.GetComponent<CanvasGroup>() ?? clone.AddComponent<CanvasGroup>();
            ghostGroup.blocksRaycasts = false;
            ghostGroup.interactable = false;
            ghostGroup.alpha = .96f;
            ghost = (RectTransform)clone.transform;
            ghost.anchorMin = ghost.anchorMax = new Vector2(.5f, .5f);
            ghost.pivot = new Vector2(.5f, .5f);
            ghost.sizeDelta = sourceRect.rect.size;
            ghost.localScale = Vector3.one * 1.02f;
            var shadow = clone.GetComponent<Shadow>() ?? clone.AddComponent<Shadow>();
            shadow.effectColor = new Color(0f, 0f, 0f, .72f);
            shadow.effectDistance = new Vector2(7f, -9f);
            foreach (var graphic in clone.GetComponentsInChildren<Graphic>(true)) graphic.raycastTarget = false;
            ghost.SetAsLastSibling();
        }

        private void UpdateTarget(Vector2 screenPosition, bool instant)
        {
            var layer = controller.FormationDragLayer;
            if (!layer || !RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    layer, screenPosition, controller.FormationEventCamera, out targetLocal)) return;
            if (!ghost) return;
            if (instant)
            {
                ghost.anchoredPosition = targetLocal;
                previousLocal = targetLocal;
            }
        }

        private void OnDisable()
        {
            if (!dragging) return;
            dragging = false;
            if (sourceGroup)
            {
                sourceGroup.alpha = 1f;
                sourceGroup.blocksRaycasts = true;
            }
            if (ghost) Destroy(ghost.gameObject);
        }
    }
}

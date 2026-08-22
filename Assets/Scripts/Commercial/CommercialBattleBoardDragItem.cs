using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform), typeof(CanvasGroup))]
    public sealed class CommercialBattleBoardDragItem : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        [SerializeField] private float followSharpness = 22f;
        [SerializeField] private float rotationSharpness = 16f;
        [SerializeField] private float rotationPerPixel = .18f;
        [SerializeField] private float maxDragRotation = 16f;
        [SerializeField] private float dragScale = 1.08f;

        private CommercialPrototypeController controller;
        private RectTransform sourceRect;
        private CanvasGroup sourceGroup;
        private RectTransform ghost;
        private Vector2 targetLocal;
        private int sourceGrid = -1;
        private bool dragging;

        public int SourceGrid => sourceGrid;

        private void Awake()
        {
            sourceRect = (RectTransform)transform;
            sourceGroup = GetComponent<CanvasGroup>();
        }

        public void Configure(CommercialPrototypeController owner, int gridIndex)
        {
            controller = owner;
            sourceGrid = gridIndex;
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            if (!controller || !controller.CanBeginBattleDrag(this)) return;
            dragging = true;
            sourceGroup.alpha = .34f;
            sourceGroup.blocksRaycasts = false;
            CreateGhost();
            UpdateTarget(eventData.position, true);
            controller.BeginBattleDrag(this);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (dragging) UpdateTarget(eventData.position, false);
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            if (!dragging) return;
            dragging = false;
            sourceGroup.alpha = 1f;
            sourceGroup.blocksRaycasts = true;
            controller.EndBattleDrag(this, eventData.position);
            if (ghost) Destroy(ghost.gameObject);
            ghost = null;
        }

        private void LateUpdate()
        {
            if (!dragging || !ghost) return;
            var follow = 1f - Mathf.Exp(-followSharpness * Time.unscaledDeltaTime);
            var next = Vector2.Lerp(ghost.anchoredPosition, targetLocal, follow);
            var lag = targetLocal.x - next.x;
            ghost.anchoredPosition = next;
            var targetRotation = Mathf.Clamp(-lag * rotationPerPixel, -maxDragRotation, maxDragRotation);
            var rotate = 1f - Mathf.Exp(-rotationSharpness * Time.unscaledDeltaTime);
            ghost.localRotation = Quaternion.Euler(0f, 0f,
                Mathf.LerpAngle(ghost.localEulerAngles.z, targetRotation, rotate));
            ghost.localScale = Vector3.Lerp(ghost.localScale, Vector3.one * dragScale, follow);
        }

        private void CreateGhost()
        {
            var layer = controller.BattleDragLayer;
            if (!layer) return;
            var go = new GameObject("BattleDragGhost", typeof(RectTransform), typeof(CanvasRenderer),
                typeof(Image), typeof(CanvasGroup));
            ghost = (RectTransform)go.transform;
            ghost.SetParent(layer, false);
            ghost.anchorMin = ghost.anchorMax = new Vector2(.5f, .5f);
            ghost.pivot = new Vector2(.5f, .5f);
            ghost.sizeDelta = sourceRect.rect.size;
            ghost.localScale = Vector3.one * 1.02f;
            var sourceImage = GetComponent<Image>();
            var ghostImage = go.GetComponent<Image>();
            ghostImage.sprite = sourceImage ? sourceImage.sprite : null;
            ghostImage.color = sourceImage ? sourceImage.color : new Color(.08f, .30f, .34f, .96f);
            ghostImage.raycastTarget = false;
            var group = go.GetComponent<CanvasGroup>();
            group.alpha = .94f;
            group.blocksRaycasts = false;
            group.interactable = false;
            CopyLabel("Name", new Vector2(.06f, .44f), new Vector2(.95f, .86f), 16, FontStyle.Bold);
            CopyLabel("Meta", new Vector2(.06f, .07f), new Vector2(.95f, .43f), 11, FontStyle.Normal);
            var shadow = go.AddComponent<Shadow>();
            shadow.effectColor = new Color(0f, 0f, 0f, .76f);
            shadow.effectDistance = new Vector2(7f, -9f);
            ghost.SetAsLastSibling();
        }

        private void CopyLabel(string childName, Vector2 min, Vector2 max, int size, FontStyle style)
        {
            var source = FindDeep(transform, childName)?.GetComponent<Text>();
            var go = new GameObject(childName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            var rect = (RectTransform)go.transform;
            rect.SetParent(ghost, false);
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            var label = go.GetComponent<Text>();
            label.font = source && source.font ? source.font : Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.text = source ? source.text : string.Empty;
            label.color = source ? source.color : Color.white;
            label.fontSize = size;
            label.fontStyle = style;
            label.alignment = TextAnchor.MiddleLeft;
            label.raycastTarget = false;
        }

        private void UpdateTarget(Vector2 screenPosition, bool instant)
        {
            var layer = controller.BattleDragLayer;
            if (!layer || !RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    layer, screenPosition, controller.BattleEventCamera, out targetLocal) || !ghost) return;
            if (instant) ghost.anchoredPosition = targetLocal;
        }

        private static Transform FindDeep(Transform root, string objectName)
        {
            if (!root) return null;
            if (root.name == objectName) return root;
            for (var i = 0; i < root.childCount; i++)
            {
                var found = FindDeep(root.GetChild(i), objectName);
                if (found) return found;
            }
            return null;
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
            ghost = null;
        }
    }
}

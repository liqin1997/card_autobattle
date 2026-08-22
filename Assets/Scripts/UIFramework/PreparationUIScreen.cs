using UnityEngine;
using UnityEngine.UI;
using CardAutobattle.Prototype;
using CardAutobattle.Exploration;
using System.Collections;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class PreparationUIScreen : UIScreenBase
    {
        [SerializeField] private GameObject preparationRoot;
        [SerializeField] private Button backToHubButton;

        public override UIScreenId ScreenId => UIScreenId.Preparation;

        protected override void OnInitialize()
        {
            if (backToHubButton)
                backToHubButton.onClick.AddListener(BackToHub);
        }

        protected override void OnOpen(object args)
        {
            StartCoroutine(BeginRunIfNeeded(args as ScavengerRecord));
        }

        private IEnumerator BeginRunIfNeeded(ScavengerRecord requested)
        {
            yield return null;
            var flow = GetComponentInChildren<PrototypeGameFlowController>(true);
            if (flow && (flow.ExplorationCompleted ||
                         requested != null && flow.CurrentScavengerId != requested.Id))
                flow.BeginNewExploration();
        }

        private void LateUpdate()
        {
            if (backToHubButton && preparationRoot)
                backToHubButton.gameObject.SetActive(preparationRoot.activeInHierarchy);
        }

        private void BackToHub()
        {
            UIRoot.Screens.Back();
        }

        public override bool HandleBack()
        {
            // Battle is hosted inside this screen for now. Do not leave a live battle accidentally.
            return preparationRoot && !preparationRoot.activeInHierarchy;
        }

#if UNITY_EDITOR
        public void EditorConfigure(GameObject preparation, Button backButton)
        {
            preparationRoot = preparation;
            backToHubButton = backButton;
        }
#endif
    }
}

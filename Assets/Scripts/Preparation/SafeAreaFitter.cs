using UnityEngine;

namespace CardAutobattle.Preparation
{
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public sealed class SafeAreaFitter : MonoBehaviour
    {
        private Rect lastSafeArea;
        private Vector2Int lastScreen;

        private void OnEnable() => Apply();
        private void Update()
        {
            if (lastSafeArea != Screen.safeArea || lastScreen.x != Screen.width || lastScreen.y != Screen.height)
                Apply();
        }

        private void Apply()
        {
            var rect = (RectTransform)transform;
            var safe = Screen.safeArea;
            if (Screen.width <= 0 || Screen.height <= 0)
                return;

            rect.anchorMin = safe.position / new Vector2(Screen.width, Screen.height);
            rect.anchorMax = (safe.position + safe.size) / new Vector2(Screen.width, Screen.height);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            lastSafeArea = safe;
            lastScreen = new Vector2Int(Screen.width, Screen.height);
        }
    }
}

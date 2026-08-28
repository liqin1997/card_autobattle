using UnityEngine;

namespace CardAutobattle.Commercial
{
    public sealed class CommercialWorldMapSafeArea : MonoBehaviour
    {
        private Rect last;
        private Vector2Int screen;
        private void Update()
        {
            var safe = Screen.safeArea;
            if (safe == last && screen.x == Screen.width && screen.y == Screen.height) return;
            last = safe; screen = new Vector2Int(Screen.width, Screen.height);
            if (screen.x <= 0 || screen.y <= 0) return;
            var r = (RectTransform)transform;
            r.anchorMin = new Vector2(safe.xMin / screen.x, safe.yMin / screen.y);
            r.anchorMax = new Vector2(safe.xMax / screen.x, safe.yMax / screen.y);
            r.offsetMin = r.offsetMax = Vector2.zero;
        }
    }
}

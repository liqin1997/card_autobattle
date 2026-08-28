using UnityEngine;

namespace CardAutobattle.Map
{
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [RequireComponent(typeof(SpriteRenderer))]
    public sealed class FogRevealController : MonoBehaviour
    {
        private static readonly int FogMaskId = Shader.PropertyToID("_FogMask");
        private static readonly int FogColorId = Shader.PropertyToID("_FogColor");
        private static readonly int BaseAlphaId = Shader.PropertyToID("_BaseAlpha");

        [Header("Fog Assets")]
        [SerializeField] private Material fogMaterialTemplate;

        [Header("Unexplored Area")]
        [SerializeField] private Color fogColor = new(0.055f, 0.075f, 0.11f, 1f);
        [SerializeField, Range(0f, 1f)] private float unexploredOpacity = 0.88f;
        [SerializeField, Range(64, 1024)] private int maskResolution = 512;

        [Header("Demo Reveal")]
        [SerializeField] private Vector2 initialRevealUv = new(0.5f, 0.52f);
        [SerializeField, Range(0.01f, 0.5f)] private float initialRevealRadius = 0.17f;
        [SerializeField, Range(0.001f, 0.25f)] private float revealEdgeSoftness = 0.055f;

        private SpriteRenderer fogRenderer;
        private Material runtimeMaterial;
        private Texture2D runtimeMask;
        private Color32[] maskPixels;

        private void OnEnable()
        {
            RebuildFog();
        }

        private void OnDisable()
        {
            ReleaseRuntimeResources();
        }

        private void OnValidate()
        {
            maskResolution = Mathf.Clamp(maskResolution, 64, 1024);
            if (isActiveAndEnabled)
                RebuildFog();
        }

        [ContextMenu("Rebuild Demo Fog")]
        public void RebuildFog()
        {
            fogRenderer = GetComponent<SpriteRenderer>();
            ReleaseRuntimeResources();

            if (!fogRenderer || !fogRenderer.sprite || !fogMaterialTemplate)
                return;

            runtimeMaterial = new Material(fogMaterialTemplate)
            {
                name = $"{fogMaterialTemplate.name} (Fog Runtime)",
                hideFlags = HideFlags.HideAndDontSave
            };
            runtimeMaterial.SetColor(FogColorId, fogColor);
            runtimeMaterial.SetFloat(BaseAlphaId, unexploredOpacity);

            runtimeMask = new Texture2D(maskResolution, maskResolution, TextureFormat.R8, false, true)
            {
                name = "Fog Reveal Mask (Runtime)",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                hideFlags = HideFlags.HideAndDontSave
            };

            maskPixels = new Color32[maskResolution * maskResolution];
            for (var i = 0; i < maskPixels.Length; i++)
                maskPixels[i] = Color.white;

            PaintReveal(initialRevealUv, initialRevealRadius, revealEdgeSoftness);
            ApplyMask();
            fogRenderer.sharedMaterial = runtimeMaterial;
        }

        /// <summary>
        /// Reveals a circular map region. The radius is expressed in world units.
        /// Calling this method repeatedly accumulates explored areas.
        /// </summary>
        public void RevealAtWorldPosition(Vector3 worldPosition, float radiusWorld, float softnessWorld = 1f)
        {
            if (!fogRenderer || !runtimeMask || maskPixels == null)
                RebuildFog();
            if (!fogRenderer || !runtimeMask || maskPixels == null)
                return;

            var bounds = fogRenderer.bounds;
            var uv = new Vector2(
                Mathf.InverseLerp(bounds.min.x, bounds.max.x, worldPosition.x),
                Mathf.InverseLerp(bounds.min.y, bounds.max.y, worldPosition.y));
            var minimumSize = Mathf.Max(0.001f, Mathf.Min(bounds.size.x, bounds.size.y));
            PaintReveal(
                uv,
                Mathf.Max(0.001f, radiusWorld / minimumSize),
                Mathf.Max(0.001f, softnessWorld / minimumSize));
            ApplyMask();
        }

        [ContextMenu("Reset To Initial Reveal")]
        public void ResetToInitialReveal()
        {
            RebuildFog();
        }

        private void PaintReveal(Vector2 centerUv, float radiusNormalized, float softnessNormalized)
        {
            if (maskPixels == null || !fogRenderer || !fogRenderer.sprite)
                return;

            var boundsSize = fogRenderer.bounds.size;
            var minimumSize = Mathf.Max(0.001f, Mathf.Min(boundsSize.x, boundsSize.y));
            var radiusWorld = radiusNormalized * minimumSize;
            var softnessWorld = Mathf.Max(0.001f, softnessNormalized * minimumSize);

            for (var y = 0; y < maskResolution; y++)
            {
                var v = (y + 0.5f) / maskResolution;
                for (var x = 0; x < maskResolution; x++)
                {
                    var u = (x + 0.5f) / maskResolution;
                    var dx = (u - centerUv.x) * boundsSize.x;
                    var dy = (v - centerUv.y) * boundsSize.y;
                    var distance = Mathf.Sqrt(dx * dx + dy * dy);
                    var fogAmount = Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(radiusWorld, radiusWorld + softnessWorld, distance));
                    var index = y * maskResolution + x;
                    var existing = maskPixels[index].r / 255f;
                    var combined = Mathf.Min(existing, fogAmount);
                    var value = (byte)Mathf.RoundToInt(combined * 255f);
                    maskPixels[index] = new Color32(value, value, value, 255);
                }
            }
        }

        private void ApplyMask()
        {
            if (!runtimeMask || runtimeMaterial == null || maskPixels == null)
                return;
            runtimeMask.SetPixels32(maskPixels);
            runtimeMask.Apply(false, false);
            runtimeMaterial.SetTexture(FogMaskId, runtimeMask);
        }

        private void ReleaseRuntimeResources()
        {
            if (fogRenderer && runtimeMaterial && fogRenderer.sharedMaterial == runtimeMaterial)
                fogRenderer.sharedMaterial = fogMaterialTemplate;

            DestroyRuntimeObject(runtimeMask);
            DestroyRuntimeObject(runtimeMaterial);
            runtimeMask = null;
            runtimeMaterial = null;
            maskPixels = null;
        }

        private static void DestroyRuntimeObject(Object target)
        {
            if (!target)
                return;
            if (Application.isPlaying)
                Destroy(target);
            else
                DestroyImmediate(target);
        }
    }
}

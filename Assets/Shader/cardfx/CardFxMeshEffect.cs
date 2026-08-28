using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Prototype
{
    /// <summary>
    /// Writes normalized 0..1 card-local coordinates to UV1. Enable "Use Local UV1"
    /// on the CardFX material when the artwork Sprite is packed into a Sprite Atlas.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Graphic))]
    public sealed class CardFxMeshEffect : BaseMeshEffect
    {
        protected override void OnEnable()
        {
            base.OnEnable();
            EnsureCanvasChannel();
            graphic.SetVerticesDirty();
        }

        public override void ModifyMesh(VertexHelper vertexHelper)
        {
            if (!IsActive() || vertexHelper.currentVertCount == 0)
                return;

            var rect = ((RectTransform)transform).rect;
            var width = Mathf.Max(1f, rect.width);
            var height = Mathf.Max(1f, rect.height);
            var vertex = default(UIVertex);

            for (var index = 0; index < vertexHelper.currentVertCount; index++)
            {
                vertexHelper.PopulateUIVertex(ref vertex, index);
                vertex.uv1 = new Vector2(
                    Mathf.Clamp01((vertex.position.x - rect.xMin) / width),
                    Mathf.Clamp01((vertex.position.y - rect.yMin) / height));
                vertexHelper.SetUIVertex(vertex, index);
            }
        }

        private void EnsureCanvasChannel()
        {
            var targetCanvas = graphic ? graphic.canvas : null;
            if (targetCanvas)
                targetCanvas.additionalShaderChannels |= AdditionalCanvasShaderChannels.TexCoord1;
        }
    }
}

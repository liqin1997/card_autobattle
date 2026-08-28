using UnityEngine;

namespace CardAutobattle.Commercial
{
    /// <summary>
    /// Bridges native ParticleSystem renderers into the battle UI camera sorting stack.
    /// Any effect instantiated below this transform is moved onto the battle camera layer
    /// and receives the configured renderer sorting order.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class CommercialBattleParticleLayer : MonoBehaviour
    {
        [SerializeField] private int sortingOrder = 50;

        public void Configure(int order)
        {
            sortingOrder = order;
            ApplyToChildren();
        }

        private void OnEnable()
        {
            ApplyToChildren();
        }

        private void OnTransformChildrenChanged()
        {
            ApplyToChildren();
        }

        private void ApplyToChildren()
        {
            var targetLayer = gameObject.layer;
            foreach (var child in GetComponentsInChildren<Transform>(true))
                child.gameObject.layer = targetLayer;

            foreach (var particleRenderer in GetComponentsInChildren<ParticleSystemRenderer>(true))
            {
                particleRenderer.sortingLayerID = 0;
                particleRenderer.sortingOrder = sortingOrder;
            }
        }
    }
}

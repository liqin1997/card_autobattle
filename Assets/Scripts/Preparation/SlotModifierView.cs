using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Preparation
{
    [DisallowMultipleComponent]
    public sealed class SlotModifierView : MonoBehaviour
    {
        [SerializeField] private Image modifierSurface;
        [SerializeField] private Image badgeBackground;
        [SerializeField] private Text badgeLabel;

        private Material runtimeMaterial;

        private static readonly int PrimaryColorId = Shader.PropertyToID("_PrimaryColor");
        private static readonly int SecondaryColorId = Shader.PropertyToID("_SecondaryColor");
        private static readonly int PatternId = Shader.PropertyToID("_Pattern");
        private static readonly int ActiveId = Shader.PropertyToID("_Active");
        private static readonly int SeedId = Shader.PropertyToID("_Seed");

        public SlotModifierType CurrentModifier { get; private set; }

        private void Awake()
        {
            if (!modifierSurface)
                modifierSurface = FindImage("ModifierSurface");
            if (!badgeBackground)
                badgeBackground = FindImage("ModifierBadge");
            if (!badgeLabel && badgeBackground)
                badgeLabel = badgeBackground.GetComponentInChildren<Text>(true);
        }

        public void SetModifier(SlotModifierType modifier)
        {
            CurrentModifier = modifier;
            EnsureMaterial();

            var visible = modifier != SlotModifierType.None;
            if (modifierSurface)
                modifierSurface.gameObject.SetActive(visible);
            if (badgeBackground)
                badgeBackground.gameObject.SetActive(false);
            if (!visible)
                return;

            GetPalette(modifier, out var primary, out var secondary, out var pattern);
            if (runtimeMaterial)
            {
                runtimeMaterial.SetColor(PrimaryColorId, primary);
                runtimeMaterial.SetColor(SecondaryColorId, secondary);
                runtimeMaterial.SetFloat(PatternId, pattern);
                runtimeMaterial.SetFloat(ActiveId, 1f);
                runtimeMaterial.SetFloat(SeedId, Mathf.Repeat(Mathf.Abs(GetInstanceID()) * .0137f, 1f));
            }

            // Slot types are communicated by the outline palette and pattern. Keeping the
            // legacy badge object disabled avoids competing with the card quality frame.
        }

        public void SetConditionActive(bool active)
        {
            if (runtimeMaterial)
                runtimeMaterial.SetFloat(ActiveId, active ? 1f : .28f);
            if (badgeBackground)
            {
                var color = badgeBackground.color;
                color.a = active ? .96f : .48f;
                badgeBackground.color = color;
            }
        }

        private void EnsureMaterial()
        {
            if (runtimeMaterial || !modifierSurface)
                return;

            var template = Resources.Load<Material>("SlotModifierSurface");
            if (!template)
                return;
            runtimeMaterial = new Material(template) { name = $"SlotModifier_{GetInstanceID()}" };
            modifierSurface.material = runtimeMaterial;
        }

        private Image FindImage(string objectName)
        {
            foreach (var image in GetComponentsInChildren<Image>(true))
                if (image.name == objectName)
                    return image;
            return null;
        }

        private static void GetPalette(SlotModifierType modifier, out Color primary, out Color secondary, out float pattern)
        {
            switch (modifier)
            {
                case SlotModifierType.FireDamage:
                    primary = new Color(1f, .22f, .035f, 1f);
                    secondary = new Color(1f, .72f, .12f, 1f);
                    pattern = 1f;
                    break;
                case SlotModifierType.DirectDamage:
                    primary = new Color(1f, .50f, .08f, 1f);
                    secondary = new Color(1f, .92f, .38f, 1f);
                    pattern = 2f;
                    break;
                case SlotModifierType.Healing:
                    primary = new Color(.10f, .88f, .46f, 1f);
                    secondary = new Color(.62f, 1f, .78f, 1f);
                    pattern = 3f;
                    break;
                case SlotModifierType.Shield:
                    primary = new Color(.10f, .58f, 1f, 1f);
                    secondary = new Color(.52f, .88f, 1f, 1f);
                    pattern = 4f;
                    break;
                case SlotModifierType.PoisonDamage:
                    primary = new Color(.58f, .16f, .92f, 1f);
                    secondary = new Color(.62f, 1f, .16f, 1f);
                    pattern = 5f;
                    break;
                case SlotModifierType.CooldownReduction:
                    primary = new Color(.08f, .82f, .94f, 1f);
                    secondary = new Color(.55f, 1f, 1f, 1f);
                    pattern = 6f;
                    break;
                default:
                    primary = Color.clear;
                    secondary = Color.clear;
                    pattern = 0f;
                    break;
            }
        }

        private void OnDestroy()
        {
            if (runtimeMaterial)
                Destroy(runtimeMaterial);
        }
    }
}

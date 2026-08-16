using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Prototype
{
    [DisallowMultipleComponent]
    public sealed class BattleCardView : MonoBehaviour
    {
        private Image surfaceBackground;
        private Image surfaceArtwork;
        private Image cooldownFrontFx;
        private float pulse;
        private float triggerFlash;
        private float currentProgress;
        private Material cooldownMaterial;
        private Material cooldownFrontMaterial;

        private static readonly int ProgressId = Shader.PropertyToID("_Progress");
        private static readonly int TriggerFlashId = Shader.PropertyToID("_TriggerFlash");
        private static readonly int FlashProgressId = Shader.PropertyToID("_FlashProgress");
        private static readonly int DarkColorId = Shader.PropertyToID("_DarkColor");
        private static readonly int EnergyColorId = Shader.PropertyToID("_EnergyColor");
        private static readonly int EdgeColorId = Shader.PropertyToID("_EdgeColor");
        private static readonly int ReadyColorId = Shader.PropertyToID("_ReadyColor");
        private static readonly int CoreColorId = Shader.PropertyToID("_CoreColor");
        private static readonly int GlowColorId = Shader.PropertyToID("_GlowColor");
        private static readonly int FlowColorId = Shader.PropertyToID("_FlowColor");
        private static readonly int PhaseOffsetId = Shader.PropertyToID("_PhaseOffset");

        public void Bind(CardDefinition definition, int level, bool enemy)
        {
            CardPresentationUtility.ApplyCardArt(transform, definition, level);
            var parts = CardPresentationUtility.GetVisualParts(transform);
            surfaceBackground = parts.SurfaceBackground;
            surfaceArtwork = parts.Artwork;
            cooldownFrontFx = parts.CooldownFrontFx;
            CardPresentationUtility.SetMetadataVisibility(transform, false, 0);
            SetupCooldownMaterial(enemy);
        }

        public void SetCooldown(float normalizedProgress)
        {
            var progress = Mathf.Clamp01(normalizedProgress);
            currentProgress = progress;
            if (cooldownMaterial)
                cooldownMaterial.SetFloat(ProgressId, progress);
            if (cooldownFrontMaterial)
                cooldownFrontMaterial.SetFloat(ProgressId, progress);
        }

        public void TriggerPulse()
        {
            pulse = 1f;
            triggerFlash = 1f;
            if (cooldownFrontMaterial)
            {
                cooldownFrontMaterial.SetFloat(FlashProgressId, Mathf.Max(.98f, currentProgress));
                cooldownFrontMaterial.SetFloat(TriggerFlashId, triggerFlash);
            }
        }

        private void Update()
        {
            if (pulse > 0f)
            {
                pulse = Mathf.Max(0f, pulse - Time.unscaledDeltaTime * 4.5f);
                var amount = Mathf.Sin(pulse * Mathf.PI) * .08f;
                transform.localScale = Vector3.one * (1f + amount);
                if (pulse <= 0f)
                    transform.localScale = Vector3.one;
            }

            if (triggerFlash > 0f)
            {
                triggerFlash = Mathf.Max(0f, triggerFlash - Time.unscaledDeltaTime * 5.5f);
                if (cooldownFrontMaterial)
                    cooldownFrontMaterial.SetFloat(TriggerFlashId, triggerFlash);
            }
        }

        private void SetupCooldownMaterial(bool enemy)
        {
            if (!surfaceBackground && !surfaceArtwork)
                return;

            var surfaceTemplate = Resources.Load<Material>("CardCooldownSweep");
            if (surfaceTemplate)
            {
                if (!cooldownMaterial)
                    cooldownMaterial = new Material(surfaceTemplate)
                    {
                        name = $"CardSurface_{(enemy ? "Enemy" : "Player")}_{GetInstanceID()}"
                    };
                if (surfaceBackground)
                    surfaceBackground.material = cooldownMaterial;
                if (surfaceArtwork)
                    surfaceArtwork.material = cooldownMaterial;
                cooldownMaterial.SetFloat(ProgressId, 0f);
                cooldownMaterial.SetFloat(TriggerFlashId, 0f);
            }

            var phase = Mathf.Repeat(Mathf.Abs(GetInstanceID()) * 0.6180339f, 1f);
            var frontTemplate = Resources.Load<Material>("CardCooldownFrontAdditive");
            if (cooldownFrontFx && frontTemplate)
            {
                if (!cooldownFrontMaterial)
                    cooldownFrontMaterial = new Material(frontTemplate)
                    {
                        name = $"CardCooldownFront_{(enemy ? "Enemy" : "Player")}_{GetInstanceID()}"
                    };
                cooldownFrontFx.gameObject.SetActive(true);
                cooldownFrontFx.type = Image.Type.Simple;
                cooldownFrontFx.color = Color.white;
                cooldownFrontFx.raycastTarget = false;
                cooldownFrontFx.material = cooldownFrontMaterial;
                cooldownFrontMaterial.SetFloat(ProgressId, 0f);
                cooldownFrontMaterial.SetFloat(FlashProgressId, 1f);
                cooldownFrontMaterial.SetFloat(TriggerFlashId, 0f);
                cooldownFrontMaterial.SetFloat(PhaseOffsetId, phase);
            }

            if (enemy)
            {
                SetSurfacePalette(
                    new Color(.055f, .015f, .02f, .57f),
                    new Color(1f, .18f, .08f, .11f),
                    new Color(1f, .34f, .10f, 0f),
                    new Color(1f, .88f, .35f, .9f));
                SetFrontPalette(
                    new Color(1f, .96f, .78f, 1f),
                    new Color(1f, .21f, .035f, .92f),
                    new Color(1f, .32f, .04f, .78f),
                    new Color(1f, .9f, .36f, 1f));
            }
            else
            {
                SetSurfacePalette(
                    new Color(.012f, .035f, .055f, .56f),
                    new Color(.02f, .82f, .68f, .11f),
                    new Color(.18f, 1f, .75f, 0f),
                    new Color(1f, .95f, .60f, .9f));
                SetFrontPalette(
                    new Color(.9f, 1f, .96f, 1f),
                    new Color(.06f, 1f, .59f, .94f),
                    new Color(.02f, .86f, .66f, .78f),
                    new Color(1f, 1f, .78f, 1f));
            }
        }

        private void SetSurfacePalette(Color dark, Color energy, Color edge, Color ready)
        {
            if (!cooldownMaterial)
                return;

            cooldownMaterial.SetColor(DarkColorId, dark);
            cooldownMaterial.SetColor(EnergyColorId, energy);
            cooldownMaterial.SetColor(EdgeColorId, edge);
            cooldownMaterial.SetColor(ReadyColorId, ready);
        }

        private void SetFrontPalette(Color core, Color glow, Color flow, Color ready)
        {
            if (!cooldownFrontMaterial)
                return;

            cooldownFrontMaterial.SetColor(CoreColorId, core);
            cooldownFrontMaterial.SetColor(GlowColorId, glow);
            cooldownFrontMaterial.SetColor(FlowColorId, flow);
            cooldownFrontMaterial.SetColor(ReadyColorId, ready);
        }

        private void ReleaseMaterials()
        {
            if (cooldownMaterial)
            {
                if (surfaceBackground && surfaceBackground.material == cooldownMaterial)
                    surfaceBackground.material = null;
                if (surfaceArtwork && surfaceArtwork.material == cooldownMaterial)
                    surfaceArtwork.material = null;
                Destroy(cooldownMaterial);
                cooldownMaterial = null;
            }

            if (cooldownFrontMaterial)
            {
                if (cooldownFrontFx && cooldownFrontFx.material == cooldownFrontMaterial)
                    cooldownFrontFx.material = null;
                Destroy(cooldownFrontMaterial);
                cooldownFrontMaterial = null;
            }
        }

        private void OnDestroy()
        {
            ReleaseMaterials();
        }
    }
}

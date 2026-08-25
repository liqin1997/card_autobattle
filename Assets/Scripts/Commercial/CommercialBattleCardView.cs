using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialBattleCardView : MonoBehaviour
    {
        private static readonly int ProgressId = Shader.PropertyToID("_Progress");
        private static readonly int TriggerFlashId = Shader.PropertyToID("_TriggerFlash");
        private static readonly int FlashProgressId = Shader.PropertyToID("_FlashProgress");
        private static readonly int PhaseOffsetId = Shader.PropertyToID("_PhaseOffset");
        private static readonly int EnergyColorId = Shader.PropertyToID("_EnergyColor");
        private static readonly int EdgeColorId = Shader.PropertyToID("_EdgeColor");
        private static readonly int ReadyColorId = Shader.PropertyToID("_ReadyColor");
        private static readonly int CoreColorId = Shader.PropertyToID("_CoreColor");
        private static readonly int GlowColorId = Shader.PropertyToID("_GlowColor");
        private static readonly int FlowColorId = Shader.PropertyToID("_FlowColor");
        private Text nameLabel;
        private Text metaLabel;
        private Text healthLabel;
        private Image surface;
        private Image cooldownFill;
        private Image cooldownSweep;
        private Image healthFill;
        private Image healthLagFill;
        private Image shieldFill;
        private GameObject healthGroup;
        private Button button;
        private Material surfaceMaterial;
        private Material sweepMaterial;
        private CommercialCardRuntime card;
        private CommercialCombatant combatant;
        private Action clickAction;
        private float flash;
        private Color baseSurfaceColor;
        private Coroutine hitRoutine;
        private Vector3 restLocalPosition;
        private bool restPositionCached;
        private float displayedHealth01 = 1f;
        private float lagHealth01 = 1f;
        private float displayedShield01;
        private float healthLagHold;
        private static readonly Color HealthyColor = new(.28f, .91f, .57f, 1f);
        private static readonly Color WoundedColor = new(1f, .63f, .18f, 1f);
        private static readonly Color CriticalColor = new(1f, .25f, .20f, 1f);

        public int GridIndex { get; private set; }

        private void Awake() => Cache();

        public void BindCard(CommercialCardRuntime runtime, int gridIndex, Action onClick)
        {
            Cache();
            RestoreRestPosition();
            card = runtime;
            combatant = runtime?.Summon;
            GridIndex = gridIndex;
            clickAction = onClick;
            ApplyIdentity(runtime?.Definition?.DisplayName ?? "空位",
                runtime?.Definition?.Type == CommercialCardType.Passive ? "常驻" :
                runtime != null ? $"{runtime.Cooldown:0.0}s" : string.Empty,
                runtime?.Definition?.Type == CommercialCardType.Summon ? new Color(.12f, .42f, .49f, 1f) :
                runtime?.Definition?.Type == CommercialCardType.Passive ? new Color(.35f, .27f, .12f, 1f) :
                new Color(.08f, .25f, .32f, 1f));
            ConfigureHealth(combatant != null);
            ConfigureCooldown(runtime != null && runtime.Definition.Type != CommercialCardType.Passive);
            gameObject.SetActive(runtime != null);
            CacheRestPosition();
        }

        public void BindHero(CommercialCombatant hero, int gridIndex, Action onClick)
        {
            Cache();
            RestoreRestPosition();
            card = null;
            combatant = hero;
            GridIndex = gridIndex;
            clickAction = onClick;
            ApplyIdentity("主角", "3.0s · 战败核心", new Color(.55f, .39f, .11f, 1f));
            ConfigureHealth(true);
            ConfigureCooldown(false);
            gameObject.SetActive(hero != null);
            CacheRestPosition();
        }

        public void BindEnemy(CommercialCombatant enemy, int gridIndex, Action onClick)
        {
            Cache();
            RestoreRestPosition();
            card = null;
            combatant = enemy;
            GridIndex = gridIndex;
            clickAction = onClick;
            ApplyIdentity(enemy?.DisplayName ?? "空位", enemy != null ? $"{enemy.AttackInterval:0.0}s" : string.Empty,
                new Color(.34f, .10f, .14f, 1f));
            ConfigureHealth(enemy != null);
            ConfigureCooldown(enemy != null, true);
            gameObject.SetActive(enemy != null);
            CacheRestPosition();
        }

        public void Refresh()
        {
            if (!gameObject.activeSelf) return;
            if (card != null)
            {
                var progress = card.Charge01;
                if (cooldownFill) cooldownFill.fillAmount = progress;
                if (surfaceMaterial) surfaceMaterial.SetFloat(ProgressId, progress);
                if (sweepMaterial) sweepMaterial.SetFloat(ProgressId, progress);
            }
            else if (combatant?.Enemy == true)
            {
                var progress = combatant.ActionCharge01;
                if (cooldownFill && cooldownFill.gameObject.activeSelf != combatant.Alive)
                    cooldownFill.gameObject.SetActive(combatant.Alive);
                if (cooldownSweep && cooldownSweep.gameObject.activeSelf != combatant.Alive)
                    cooldownSweep.gameObject.SetActive(combatant.Alive);
                if (cooldownFill) cooldownFill.fillAmount = progress;
                if (surfaceMaterial) surfaceMaterial.SetFloat(ProgressId, progress);
                if (sweepMaterial) sweepMaterial.SetFloat(ProgressId, progress);
            }
            if (combatant != null)
            {
                var delta = Time.unscaledDeltaTime;
                var targetHealth = combatant.Health01;
                if (!combatant.Alive)
                {
                    // A completed battle can stop advancing immediately after the lethal hit.
                    // Never leave the red damage-trail fill looking like remaining health.
                    displayedHealth01 = 0f;
                    lagHealth01 = 0f;
                    healthLagHold = 0f;
                }
                else if (targetHealth < displayedHealth01)
                {
                    displayedHealth01 = Mathf.MoveTowards(displayedHealth01, targetHealth, delta * 5.5f);
                    healthLagHold = .16f;
                }
                else
                {
                    displayedHealth01 = Mathf.MoveTowards(displayedHealth01, targetHealth, delta * 3.5f);
                    lagHealth01 = Mathf.MoveTowards(lagHealth01, displayedHealth01, delta * 4f);
                }
                if (healthLagHold > 0f) healthLagHold -= delta;
                else lagHealth01 = Mathf.MoveTowards(lagHealth01, displayedHealth01, delta * 1.35f);
                displayedShield01 = Mathf.MoveTowards(displayedShield01,
                    Mathf.Clamp01(combatant.Shield / Mathf.Max(1f, combatant.MaxHealth)), delta * 4.5f);
                SetHorizontalFill(healthFill, displayedHealth01, false);
                SetHorizontalFill(healthLagFill, Mathf.Max(displayedHealth01, lagHealth01), false);
                SetHorizontalFill(shieldFill, displayedShield01, true);
                if (healthFill) healthFill.color = HealthColor(targetHealth);
                if (healthLabel) healthLabel.text = !combatant.Alive
                    ? $"阵亡 · HP 0/{Mathf.CeilToInt(combatant.MaxHealth)}"
                    : combatant.Shield > .01f
                        ? $"HP {Mathf.CeilToInt(combatant.Health)}/{Mathf.CeilToInt(combatant.MaxHealth)}  盾 {Mathf.CeilToInt(combatant.Shield)}"
                        : $"HP {Mathf.CeilToInt(combatant.Health)}/{Mathf.CeilToInt(combatant.MaxHealth)}";
                if (!combatant.Alive && surface && hitRoutine == null)
                    surface.color = Color.Lerp(baseSurfaceColor, Color.black, .72f);
            }
            if (flash > 0f)
            {
                flash = Mathf.Max(0f, flash - Time.unscaledDeltaTime * 5f);
                if (surfaceMaterial) surfaceMaterial.SetFloat(TriggerFlashId, flash);
                if (sweepMaterial) sweepMaterial.SetFloat(TriggerFlashId, flash);
            }
        }

        public void FlashAction()
        {
            flash = 1f;
            if (surfaceMaterial) surfaceMaterial.SetFloat(TriggerFlashId, 1f);
            if (sweepMaterial) sweepMaterial.SetFloat(TriggerFlashId, 1f);
            if (sweepMaterial) sweepMaterial.SetFloat(FlashProgressId, 1f);
        }

        public void ReceiveHit(Vector2 screenDirection)
        {
            if (!gameObject.activeInHierarchy) return;
            if (hitRoutine != null)
            {
                StopCoroutine(hitRoutine);
                ((RectTransform)transform).localPosition = restLocalPosition;
                if (surface) surface.color = baseSurfaceColor;
                hitRoutine = null;
            }
            hitRoutine = StartCoroutine(HitFeedback(screenDirection));
        }

        private void ApplyIdentity(string displayName, string meta, Color color)
        {
            if (nameLabel) nameLabel.text = displayName;
            if (metaLabel) metaLabel.text = meta;
            if (surface) surface.color = color;
            baseSurfaceColor = color;
            if (button)
            {
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => clickAction?.Invoke());
            }
        }

        private void ConfigureHealth(bool visible)
        {
            if (healthGroup) healthGroup.SetActive(visible);
            if (!visible) return;
            displayedHealth01 = combatant?.Health01 ?? 1f;
            lagHealth01 = displayedHealth01;
            displayedShield01 = combatant == null ? 0f :
                Mathf.Clamp01(combatant.Shield / Mathf.Max(1f, combatant.MaxHealth));
            healthLagHold = 0f;
            SetHorizontalFill(healthFill, displayedHealth01, false);
            SetHorizontalFill(healthLagFill, lagHealth01, false);
            SetHorizontalFill(shieldFill, displayedShield01, true);
            if (healthFill) healthFill.color = HealthColor(displayedHealth01);
            if (healthLabel && combatant != null)
                healthLabel.text = !combatant.Alive
                    ? $"阵亡 · HP 0/{Mathf.CeilToInt(combatant.MaxHealth)}"
                    : combatant.Shield > .01f
                        ? $"HP {Mathf.CeilToInt(combatant.Health)}/{Mathf.CeilToInt(combatant.MaxHealth)}  盾 {Mathf.CeilToInt(combatant.Shield)}"
                        : $"HP {Mathf.CeilToInt(combatant.Health)}/{Mathf.CeilToInt(combatant.MaxHealth)}";
        }

        private static Color HealthColor(float health01)
        {
            if (health01 <= .25f) return CriticalColor;
            if (health01 <= .5f)
                return Color.Lerp(CriticalColor, WoundedColor, Mathf.InverseLerp(.25f, .5f, health01));
            return Color.Lerp(WoundedColor, HealthyColor, Mathf.InverseLerp(.5f, .72f, health01));
        }

        private static void SetHorizontalFill(Image image, float amount, bool fromRight)
        {
            if (!image) return;
            amount = Mathf.Clamp01(amount);
            image.type = Image.Type.Simple;
            var rect = image.rectTransform;
            var minY = image.name == "ShieldFill" ? .76f : 0f;
            rect.anchorMin = new Vector2(fromRight ? 1f - amount : 0f, minY);
            rect.anchorMax = new Vector2(fromRight ? 1f : amount, 1f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private void ConfigureCooldown(bool visible, bool hostile = false)
        {
            if (cooldownFill) cooldownFill.gameObject.SetActive(visible);
            if (cooldownSweep) cooldownSweep.gameObject.SetActive(visible);
            ReleaseMaterials();
            if (!visible) return;

            var surfaceTemplate = Resources.Load<Material>("CardCooldownSweep");
            if (surface && surfaceTemplate)
            {
                surfaceMaterial = new Material(surfaceTemplate) { name = $"CommercialSurface_{GetInstanceID()}" };
                surface.material = surfaceMaterial;
                surfaceMaterial.SetFloat(ProgressId, 0f);
                surfaceMaterial.SetFloat(TriggerFlashId, 0f);
                if (hostile)
                {
                    surfaceMaterial.SetColor(EnergyColorId, new Color(1f, .18f, .08f, .22f));
                    surfaceMaterial.SetColor(EdgeColorId, new Color(1f, .34f, .12f, 1f));
                    surfaceMaterial.SetColor(ReadyColorId, new Color(1f, .68f, .20f, .95f));
                }
            }

            var frontTemplate = Resources.Load<Material>("CardCooldownFrontAdditive");
            if (!cooldownSweep || !frontTemplate) return;
            sweepMaterial = new Material(frontTemplate) { name = $"CommercialCooldownFront_{GetInstanceID()}" };
            cooldownSweep.material = sweepMaterial;
            cooldownSweep.type = Image.Type.Simple;
            cooldownSweep.color = Color.white;
            sweepMaterial.SetFloat(ProgressId, 0f);
            sweepMaterial.SetFloat(FlashProgressId, 1f);
            sweepMaterial.SetFloat(TriggerFlashId, 0f);
            sweepMaterial.SetFloat(PhaseOffsetId, Mathf.Repeat(Mathf.Abs(GetInstanceID()) * .6180339f, 1f));
            if (hostile)
            {
                sweepMaterial.SetColor(CoreColorId, new Color(1f, .94f, .78f, 1f));
                sweepMaterial.SetColor(GlowColorId, new Color(1f, .20f, .06f, .95f));
                sweepMaterial.SetColor(FlowColorId, new Color(1f, .10f, .04f, .78f));
                sweepMaterial.SetColor(ReadyColorId, new Color(1f, .72f, .24f, 1f));
            }
        }

        private void Cache()
        {
            if (surface) return;
            surface = GetComponent<Image>();
            button = GetComponent<Button>() ?? gameObject.AddComponent<Button>();
            button.targetGraphic = surface;
            nameLabel = Find("Name")?.GetComponent<Text>();
            metaLabel = Find("Meta")?.GetComponent<Text>();
            healthLabel = Find("HealthText")?.GetComponent<Text>();
            cooldownFill = Find("CooldownFill")?.GetComponent<Image>();
            cooldownSweep = Find("CooldownSweep")?.GetComponent<Image>();
            healthFill = Find("HealthFill")?.GetComponent<Image>();
            healthGroup = Find("HealthGroup")?.gameObject;
            EnsureHealthVisuals();
        }

        private void EnsureHealthVisuals()
        {
            if (!healthGroup) return;
            var track = healthGroup.GetComponent<Image>();
            if (track) track.color = new Color(.018f, .027f, .032f, .96f);
            var groupRect = (RectTransform)healthGroup.transform;
            groupRect.anchorMin = new Vector2(.05f, .035f);
            groupRect.anchorMax = new Vector2(.95f, .235f);
            groupRect.offsetMin = groupRect.offsetMax = Vector2.zero;
            if (healthLabel)
            {
                healthLabel.fontSize = 22;
                healthLabel.resizeTextForBestFit = true;
                healthLabel.resizeTextMinSize = 16;
                healthLabel.resizeTextMaxSize = 24;
                healthLabel.raycastTarget = false;
                healthLabel.transform.SetAsLastSibling();
            }
            healthLagFill = Find("HealthLagFill")?.GetComponent<Image>() ??
                            CreateRuntimeFill("HealthLagFill", new Color(.95f, .20f, .13f, .78f), false);
            if (healthLagFill) healthLagFill.transform.SetSiblingIndex(0);
            shieldFill = Find("ShieldFill")?.GetComponent<Image>() ??
                         CreateRuntimeFill("ShieldFill", new Color(.20f, .78f, 1f, .95f), true);
            if (shieldFill)
            {
                var rect = shieldFill.rectTransform;
                rect.anchorMin = new Vector2(0f, .76f);
                rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                if (healthLabel) shieldFill.transform.SetSiblingIndex(healthLabel.transform.GetSiblingIndex());
            }
            if (healthLabel) healthLabel.transform.SetAsLastSibling();
        }

        private Image CreateRuntimeFill(string objectName, Color color, bool fromRight)
        {
            var go = new GameObject(objectName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            var rect = (RectTransform)go.transform;
            rect.SetParent(healthGroup.transform, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            var image = go.GetComponent<Image>();
            image.color = color;
            image.type = Image.Type.Simple;
            image.raycastTarget = false;
            return image;
        }

        private Transform Find(string childName)
        {
            foreach (var child in GetComponentsInChildren<Transform>(true))
                if (child.name == childName) return child;
            return null;
        }

        private IEnumerator HitFeedback(Vector2 screenDirection)
        {
            var rect = (RectTransform)transform;
            var start = restPositionCached ? restLocalPosition : rect.localPosition;
            var direction = screenDirection.sqrMagnitude > .001f ? screenDirection.normalized : Vector2.down;
            var localDirection = new Vector3(direction.x, direction.y, 0f);
            const float duration = .20f;
            for (var elapsed = 0f; elapsed < duration; elapsed += Time.unscaledDeltaTime)
            {
                var t = Mathf.Clamp01(elapsed / duration);
                var kick = Mathf.Sin(t * Mathf.PI) * (1f - t) * 32f;
                var shake = Mathf.Sin(t * Mathf.PI * 6f) * (1f - t) * 6f;
                rect.localPosition = start + localDirection * kick + Vector3.right * shake;
                if (surface) surface.color = Color.Lerp(Color.white, baseSurfaceColor, Mathf.SmoothStep(0f, 1f, t));
                yield return null;
            }
            rect.localPosition = start;
            if (surface) surface.color = combatant != null && !combatant.Alive
                ? Color.Lerp(baseSurfaceColor, Color.black, .72f)
                : baseSurfaceColor;
            hitRoutine = null;
        }

        private void CacheRestPosition()
        {
            restLocalPosition = ((RectTransform)transform).localPosition;
            restPositionCached = true;
        }

        private void RestoreRestPosition()
        {
            if (hitRoutine != null) StopCoroutine(hitRoutine);
            hitRoutine = null;
            if (restPositionCached) ((RectTransform)transform).localPosition = restLocalPosition;
        }

        private void ReleaseMaterials()
        {
            if (surfaceMaterial)
            {
                if (surface && surface.material == surfaceMaterial) surface.material = null;
                Destroy(surfaceMaterial);
                surfaceMaterial = null;
            }
            if (sweepMaterial)
            {
                if (cooldownSweep && cooldownSweep.material == sweepMaterial) cooldownSweep.material = null;
                Destroy(sweepMaterial);
                sweepMaterial = null;
            }
        }

        private void OnDisable()
        {
            if (hitRoutine != null) StopCoroutine(hitRoutine);
            hitRoutine = null;
            if (restPositionCached) ((RectTransform)transform).localPosition = restLocalPosition;
        }

        private void OnDestroy() => ReleaseMaterials();
    }

}

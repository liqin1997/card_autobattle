using System;
using System.Collections;
using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    public enum CommercialPrimaryValueKind { Damage, Shield, Heal, CooldownAdvance, BuffPercent }

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
        private static readonly int ExposureId = Shader.PropertyToID("_Exposure");
        private Text nameLabel;
        private Text metaLabel;
        private Text healthLabel;
        private Image surface;
        private Image accentImage;
        private Image tagBadge;
        private Image cooldownFill;
        private Image cooldownSweep;
        private Image statusFill;
        private Image healthFill;
        private Image healthLagFill;
        private Image shieldFill;
        private GameObject healthGroup;
        private GameObject statusGroup;
        private Button button;
        private Text tagLabel;
        private Text powerLabel;
        private Text powerDeltaLabel;
        private Image powerBackdrop;
        private Text statusLabel;
        private Material surfaceMaterial;
        private Material sweepMaterial;
        private CommercialCardRuntime card;
        private CommercialCombatant combatant;
        private Action clickAction;
        private float flash;
        private float artworkExposure = 1f;
        private Color baseSurfaceColor;
        private Coroutine hitRoutine;
        private Vector3 restLocalPosition;
        private bool restPositionCached;
        private float displayedHealth01 = 1f;
        private float lagHealth01 = 1f;
        private float displayedShield01;
        private float healthLagHold;
        private float displayedPrimaryValue;
        private CommercialPrimaryValueKind primaryValueKind;
        private Tween primaryValueTween;
        private Sequence primaryPulseSequence;
        private static readonly Color HealthyColor = new(.28f, .91f, .57f, 1f);
        private static readonly Color WoundedColor = new(1f, .63f, .18f, 1f);
        private static readonly Color CriticalColor = new(1f, .25f, .20f, 1f);
        private static Sprite solidMaskSprite;

        public int GridIndex { get; private set; }

        private void Awake() => Cache();

        public void BindCard(CommercialCardRuntime runtime, int gridIndex, Action onClick)
        {
            Cache();
            StopPrimaryValueAnimation();
            RestoreRestPosition();
            card = runtime;
            // V2 cards are effect carriers only. Summon HP/state belongs to the arena disc.
            combatant = null;
            GridIndex = gridIndex;
            clickAction = onClick;
            ApplyIdentity(runtime?.Definition?.DisplayName ?? "空位",
                runtime?.Definition?.Type == CommercialCardType.Passive ? "常驻" :
                runtime != null ? $"{runtime.Cooldown:0.0}s" : string.Empty,
                runtime?.Definition?.Type == CommercialCardType.Summon ? new Color(.12f, .42f, .49f, 1f) :
                runtime?.Definition?.Type == CommercialCardType.Passive ? new Color(.35f, .27f, .12f, 1f) :
                new Color(.08f, .25f, .32f, 1f));
            ApplyCardArtwork(runtime?.Definition, false, -1);
            ConfigureHealth(false);
            ConfigureStatus(true, runtime);
            ConfigureCooldown(runtime != null && runtime.Definition.Type != CommercialCardType.Passive);
            gameObject.SetActive(runtime != null);
            CacheRestPosition();
        }

        public void BindHero(CommercialCombatant hero, int gridIndex, Action onClick)
        {
            Cache();
            StopPrimaryValueAnimation();
            RestoreRestPosition();
            card = null;
            combatant = hero;
            GridIndex = gridIndex;
            clickAction = onClick;
            var profession = hero == null ? null : CommercialProfessionCatalog.Get(hero.Profession);
            ApplyIdentity("主角", hero == null ? string.Empty : $"{hero.AttackInterval:0.0}s · {profession.DisplayName}",
                profession?.Accent ?? new Color(.55f, .39f, .11f, 1f));
            ApplyCardArtwork(null, true, -1);
            ConfigureHealth(true);
            ConfigureStatus(true, null);
            ConfigureHeroStatusLayout();
            RefreshProfessionStatus();
            ConfigureCooldown(hero != null);
            gameObject.SetActive(hero != null);
            CacheRestPosition();
        }

        public void BindEnemy(CommercialCombatant enemy, int gridIndex, Action onClick)
        {
            Cache();
            StopPrimaryValueAnimation();
            RestoreRestPosition();
            card = null;
            combatant = enemy;
            GridIndex = gridIndex;
            clickAction = onClick;
            ApplyIdentity(enemy?.DisplayName ?? "空位", enemy != null ? $"{enemy.AttackInterval:0.0}s" : string.Empty,
                new Color(.34f, .10f, .14f, 1f));
            ApplyCardArtwork(null, false, enemy?.GridIndex ?? gridIndex);
            ConfigureHealth(enemy != null);
            ConfigureStatus(false, null);
            ConfigureCooldown(enemy != null, true);
            gameObject.SetActive(enemy != null);
            CacheRestPosition();
        }

        public void SetPrimaryValue(float value, CommercialPrimaryValueKind kind, float? previousValue = null)
        {
            Cache();
            if (!powerLabel) return;
            value = Mathf.Max(0f, value);
            primaryValueKind = kind;
            var from = Mathf.Max(0f, previousValue ?? value);
            StopPrimaryValueAnimation();
            displayedPrimaryValue = from;
            RefreshPrimaryValueLabel();

            if (!previousValue.HasValue || Mathf.Abs(value - from) < .01f)
            {
                displayedPrimaryValue = value;
                powerLabel.color = Color.white;
                RefreshPrimaryValueLabel();
                return;
            }

            var increased = value > from;
            var changeColor = increased ? new Color(.35f, 1f, .50f) : new Color(1f, .38f, .30f);
            powerLabel.color = changeColor;
            ShowPrimaryDelta(from, value, changeColor);

            primaryValueTween = DOTween.To(() => displayedPrimaryValue, current =>
                {
                    displayedPrimaryValue = current;
                    RefreshPrimaryValueLabel();
                }, value, .42f)
                .SetEase(Ease.OutCubic)
                .SetUpdate(true)
                .SetTarget(this)
                .OnComplete(() =>
                {
                    displayedPrimaryValue = value;
                    RefreshPrimaryValueLabel();
                });

            primaryPulseSequence = DOTween.Sequence()
                .SetUpdate(true)
                .SetTarget(this)
                .Join(powerLabel.rectTransform.DOPunchScale(new Vector3(.24f, .24f, 0f), .48f, 7, .55f))
                .Join(powerLabel.rectTransform.DOPunchAnchorPos(new Vector2(0f, 16f), .48f, 7, .55f))
                .Append(powerLabel.DOColor(Color.white, .20f));
        }

        public void Refresh()
        {
            if (!gameObject.activeSelf) return;
            if (card != null)
            {
                SetCooldownProgress(card.Charge01);
                RefreshStatus(card);
            }
            else if (combatant != null && (combatant.Enemy || combatant.IsHero))
            {
                var progress = combatant.ActionCharge01;
                if (cooldownFill && cooldownFill.gameObject.activeSelf != combatant.Alive)
                    cooldownFill.gameObject.SetActive(combatant.Alive);
                if (cooldownSweep && cooldownSweep.gameObject.activeSelf != combatant.Alive)
                    cooldownSweep.gameObject.SetActive(combatant.Alive);
                SetCooldownProgress(progress);
                if (combatant.IsHero) RefreshProfessionStatus();
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
            if (surface) surface.color = surface.sprite ? Color.white : color;
            if (accentImage) accentImage.color = color;
            baseSurfaceColor = surface ? surface.color : color;
            if (button)
            {
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => clickAction?.Invoke());
            }
        }

        private void ApplyCardArtwork(CommercialCardDefinition definition, bool hero, int enemyIndex)
        {
            var key = hero ? "hero_swordsman" : enemyIndex >= 0
                ? EnemyArtworkKey(enemyIndex)
                : CardArtworkKey(definition);
            artworkExposure = ArtworkExposure(key);
            if (surface)
            {
                surface.sprite = LoadBattleSprite($"battle_card_art_{key}_544x336");
                surface.color = surface.sprite ? Color.white : baseSurfaceColor;
                surface.type = Image.Type.Simple;
            }
            if (powerLabel)
            {
                var power = hero && combatant != null ? combatant.Attack * 8f :
                    definition != null ? definition.Power : combatant != null ? combatant.Attack * 8f : 0f;
                powerLabel.text = Mathf.Max(1, Mathf.RoundToInt(power)).ToString();
            }
            if (tagLabel) tagLabel.text = hero ? "主角" : TagName(definition, combatant?.Enemy == true);
            if (tagBadge) tagBadge.color = TagColor(definition, hero, combatant?.Enemy == true);
        }

        private void RefreshPrimaryValueLabel()
        {
            if (!powerLabel) return;
            powerLabel.text = primaryValueKind switch
            {
                CommercialPrimaryValueKind.Shield => $"盾 {Mathf.RoundToInt(displayedPrimaryValue)}",
                CommercialPrimaryValueKind.Heal => $"疗 {Mathf.RoundToInt(displayedPrimaryValue)}",
                CommercialPrimaryValueKind.CooldownAdvance => $"速 {displayedPrimaryValue:0.0}s",
                CommercialPrimaryValueKind.BuffPercent => $"增 {displayedPrimaryValue * 100f:0}%",
                _ => $"伤 {Mathf.RoundToInt(displayedPrimaryValue)}"
            };
        }

        private void ShowPrimaryDelta(float from, float to, Color color)
        {
            if (!powerDeltaLabel) return;
            powerDeltaLabel.DOKill();
            powerDeltaLabel.rectTransform.DOKill();
            powerDeltaLabel.gameObject.SetActive(true);
            powerDeltaLabel.text = primaryValueKind == CommercialPrimaryValueKind.BuffPercent
                ? $"{from * 100f:0}% → {to * 100f:0}%"
                : primaryValueKind == CommercialPrimaryValueKind.CooldownAdvance
                    ? $"{from:0.0}s → {to:0.0}s"
                    : $"{Mathf.RoundToInt(from)} → {Mathf.RoundToInt(to)}";
            color.a = 1f;
            powerDeltaLabel.color = color;
            powerDeltaLabel.rectTransform.anchoredPosition = Vector2.zero;
            var sequence = DOTween.Sequence().SetUpdate(true).SetTarget(powerDeltaLabel);
            sequence.Join(powerDeltaLabel.rectTransform.DOAnchorPosY(34f, .62f).SetEase(Ease.OutQuad));
            sequence.Insert(.20f, powerDeltaLabel.DOFade(0f, .42f));
            sequence.OnComplete(() =>
            {
                if (powerDeltaLabel) powerDeltaLabel.gameObject.SetActive(false);
            });
        }

        private void StopPrimaryValueAnimation()
        {
            primaryValueTween?.Kill();
            primaryPulseSequence?.Kill();
            primaryValueTween = null;
            primaryPulseSequence = null;
            if (powerLabel)
            {
                powerLabel.rectTransform.DOKill();
                powerLabel.rectTransform.localScale = Vector3.one;
                powerLabel.rectTransform.anchoredPosition = Vector2.zero;
                powerLabel.color = Color.white;
            }
            if (powerDeltaLabel)
            {
                powerDeltaLabel.DOKill();
                powerDeltaLabel.rectTransform.DOKill();
                powerDeltaLabel.gameObject.SetActive(false);
            }
        }

        private static Sprite LoadBattleSprite(string name) =>
            Resources.Load<Sprite>($"Commercial/BattleUI/{name}");

        private static float ArtworkExposure(string key) => key switch
        {
            "sword_relic" => 2.65f,
            "summon_skull" => 2.05f,
            "thunder_cannon" => 1.65f,
            "defense_shield" => 1.65f,
            "gun_rifle" => 1.32f,
            _ => 1f
        };

        private static string EnemyArtworkKey(int index) => (index % 6) switch
        {
            0 => "summon_skull",
            1 => "defense_shield",
            2 => "sword_relic",
            3 => "thunder_cannon",
            4 => "gun_rifle",
            _ => "hero_swordsman"
        };

        private static string CardArtworkKey(CommercialCardDefinition definition)
        {
            if (definition == null) return "summon_skull";
            if (definition.Id == "stone_guard" || definition.Tags.HasFlag(CommercialCardTag.Defense)) return "defense_shield";
            if (definition.Id == "arc_battery" || definition.Tags.HasFlag(CommercialCardTag.Magic)) return "thunder_cannon";
            if (definition.Id == "longbow" || definition.Id == "quick_dagger") return "gun_rifle";
            if (definition.Tags.HasFlag(CommercialCardTag.Weapon)) return "sword_relic";
            return definition.Tags.HasFlag(CommercialCardTag.Summon) ? "summon_skull" : "thunder_cannon";
        }

        private static string TagName(CommercialCardDefinition definition, bool enemy)
        {
            if (enemy) return "敌袭";
            if (definition == null) return "空位";
            if (definition.Tags.HasFlag(CommercialCardTag.Summon)) return "召唤";
            if (definition.Tags.HasFlag(CommercialCardTag.Defense)) return "防御";
            if (definition.Tags.HasFlag(CommercialCardTag.Weapon)) return "剑系";
            if (definition.Tags.HasFlag(CommercialCardTag.Magic)) return "魔法";
            return "支援";
        }

        private static Color TagColor(CommercialCardDefinition definition, bool hero, bool enemy)
        {
            if (hero) return new Color(.48f, .30f, .10f, 1f);
            if (enemy) return new Color(.38f, .10f, .12f, 1f);
            if (definition == null) return new Color(.25f, .25f, .25f, 1f);
            if (definition.Tags.HasFlag(CommercialCardTag.Summon)) return new Color(.32f, .18f, .45f, 1f);
            if (definition.Tags.HasFlag(CommercialCardTag.Defense)) return new Color(.45f, .28f, .10f, 1f);
            if (definition.Tags.HasFlag(CommercialCardTag.Weapon)) return new Color(.16f, .35f, .34f, 1f);
            if (definition.Tags.HasFlag(CommercialCardTag.Magic)) return new Color(.16f, .27f, .42f, 1f);
            return new Color(.20f, .34f, .27f, 1f);
        }

        private void ConfigureStatus(bool visible, CommercialCardRuntime runtime)
        {
            if (statusGroup) statusGroup.SetActive(visible);
            if (!visible) return;
            var statusRect = statusGroup.transform as RectTransform;
            if (statusRect != null)
            {
                statusRect.anchorMin = new Vector2(.05f, .035f);
                statusRect.anchorMax = new Vector2(.95f, .235f);
                statusRect.offsetMin = statusRect.offsetMax = Vector2.zero;
            }
            var passive = runtime?.Definition?.Type == CommercialCardType.Passive;
            if (statusFill)
            {
                statusFill.sprite = statusFill.sprite ? statusFill.sprite : SolidMaskSprite();
                statusFill.type = Image.Type.Filled;
                statusFill.fillMethod = Image.FillMethod.Horizontal;
                statusFill.fillOrigin = (int)Image.OriginHorizontal.Left;
                statusFill.gameObject.SetActive(!passive);
                statusFill.fillAmount = passive ? 1f : runtime?.Charge01 ?? 0f;
                statusFill.color = passive ? new Color(.72f, .54f, .20f, .95f) : new Color(.23f, .70f, .68f, .95f);
            }
            if (statusLabel) statusLabel.text = passive ? "常驻" : $"CD {runtime?.Remaining:0.0}s";
        }

        private void ConfigureHeroStatusLayout()
        {
            if (!statusGroup) return;
            var rect = (RectTransform)statusGroup.transform;
            rect.anchorMin = new Vector2(.05f, .235f);
            rect.anchorMax = new Vector2(.95f, .355f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            if (statusFill)
            {
                statusFill.gameObject.SetActive(true);
                statusFill.sprite = statusFill.sprite ? statusFill.sprite : SolidMaskSprite();
                statusFill.type = Image.Type.Filled;
                statusFill.fillMethod = Image.FillMethod.Horizontal;
                statusFill.fillOrigin = (int)Image.OriginHorizontal.Left;
            }
        }

        private void RefreshProfessionStatus()
        {
            if (!statusGroup || !statusGroup.activeSelf || combatant?.IsHero != true) return;
            var max = Mathf.Max(1, combatant.ProfessionResourceMax);
            if (statusFill)
            {
                statusFill.fillAmount = Mathf.Clamp01(combatant.ProfessionResource / (float)max);
                statusFill.color = CommercialProfessionCatalog.Get(combatant.Profession).Accent;
            }
            if (statusLabel) statusLabel.text = combatant.ProfessionReady
                ? $"{combatant.ProfessionResourceName} · READY"
                : $"{combatant.ProfessionResourceName} {combatant.ProfessionResource}/{max}";
        }

        private void RefreshStatus(CommercialCardRuntime runtime)
        {
            if (!statusGroup || !statusGroup.activeSelf || runtime == null) return;
            if (runtime.Definition.Type == CommercialCardType.Passive)
            {
                if (statusLabel) statusLabel.text = "常驻";
                return;
            }
            if (statusFill) statusFill.fillAmount = runtime.Charge01;
            if (statusLabel) statusLabel.text = $"CD {runtime.Remaining:0.0}s";
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
            ConfigureArtworkTone();
            if (!visible) return;
            if (cooldownFill)
            {
                // A Filled Image without a sprite renders nothing. The builder may
                // not have a built-in sprite available, so guarantee a solid mask at runtime.
                cooldownFill.sprite = cooldownFill.sprite ? cooldownFill.sprite : SolidMaskSprite();
                cooldownFill.type = Image.Type.Filled;
                cooldownFill.fillMethod = Image.FillMethod.Vertical;
                // The dark mask occupies the area ABOVE the rising scan line.
                // As progress grows from 0 to 1, this top-origin fill shrinks upward.
                cooldownFill.fillOrigin = (int)Image.OriginVertical.Top;
                cooldownFill.fillClockwise = true;
                cooldownFill.color = new Color(0f, 0f, 0f, .5f);
            }

            var frontTemplate = Resources.Load<Material>("CardCooldownFrontAdditive");
            if (!cooldownSweep || !frontTemplate) return;
            sweepMaterial = new Material(frontTemplate) { name = $"CommercialCooldownFront_{GetInstanceID()}" };
            cooldownSweep.material = sweepMaterial;
            cooldownSweep.type = Image.Type.Simple;
            cooldownSweep.color = Color.white;
            SetCooldownProgress(card != null ? card.Charge01 : combatant?.ActionCharge01 ?? 0f);
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

        private void ConfigureArtworkTone()
        {
            if (!surface) return;
            var shader = Shader.Find("UI/CardArtworkExposure");
            if (!shader)
            {
                surface.material = null;
                return;
            }
            surfaceMaterial = new Material(shader) { name = $"CardArtworkTone_{GetInstanceID()}" };
            surfaceMaterial.SetFloat(ExposureId, artworkExposure);
            surface.material = surfaceMaterial;
        }

        private static Sprite SolidMaskSprite()
        {
            if (solidMaskSprite) return solidMaskSprite;
            var texture = new Texture2D(1, 1, TextureFormat.RGBA32, false, true)
            {
                name = "Runtime_CooldownMask_1x1",
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp,
                hideFlags = HideFlags.HideAndDontSave
            };
            texture.SetPixel(0, 0, Color.white);
            texture.Apply(false, true);
            solidMaskSprite = Sprite.Create(texture, new Rect(0f, 0f, 1f, 1f),
                new Vector2(.5f, .5f), 1f);
            solidMaskSprite.name = "Runtime_CooldownMask_1x1";
            solidMaskSprite.hideFlags = HideFlags.HideAndDontSave;
            return solidMaskSprite;
        }

        private void SetCooldownProgress(float progress)
        {
            progress = Mathf.Clamp01(progress);
            // Bottom-to-top reveal: 0 = fully dark, 0.5 = top half dark, 1 = no mask.
            if (cooldownFill) cooldownFill.fillAmount = 1f - progress;
            if (sweepMaterial) sweepMaterial.SetFloat(ProgressId, progress);
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
            accentImage = Find("Accent")?.GetComponent<Image>();
            tagBadge = Find("TagBadge")?.GetComponent<Image>();
            tagLabel = Find("TagText")?.GetComponent<Text>();
            powerLabel = Find("PowerText")?.GetComponent<Text>();
            powerBackdrop = Find("PowerBackdrop")?.GetComponent<Image>();
            powerDeltaLabel = Find("PowerDeltaText")?.GetComponent<Text>() ?? CreatePowerDeltaLabel();
            statusGroup = Find("StatusGroup")?.gameObject;
            statusFill = Find("StatusFill")?.GetComponent<Image>();
            statusLabel = Find("StatusText")?.GetComponent<Text>();
            cooldownFill = Find("CooldownFill")?.GetComponent<Image>();
            cooldownSweep = Find("CooldownSweep")?.GetComponent<Image>();
            healthFill = Find("HealthFill")?.GetComponent<Image>();
            healthGroup = Find("HealthGroup")?.gameObject;
            if (tagLabel) tagLabel.transform.SetAsLastSibling();
            if (powerBackdrop) powerBackdrop.transform.SetAsLastSibling();
            if (powerLabel) powerLabel.transform.SetAsLastSibling();
            if (powerDeltaLabel) powerDeltaLabel.transform.SetAsLastSibling();
            EnsureHealthVisuals();
        }

        private Text CreatePowerDeltaLabel()
        {
            var go = new GameObject("PowerDeltaText", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            var rect = (RectTransform)go.transform;
            rect.SetParent(transform, false);
            rect.anchorMin = new Vector2(.04f, .58f);
            rect.anchorMax = new Vector2(.58f, .76f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            var text = go.GetComponent<Text>();
            text.font = powerLabel ? powerLabel.font : Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = powerLabel ? Mathf.Max(18, powerLabel.fontSize / 2) : 20;
            text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter;
            text.raycastTarget = false;
            text.gameObject.SetActive(false);
            return text;
        }

        private void EnsureHealthVisuals()
        {
            if (!healthGroup) return;
            var track = healthGroup.GetComponent<Image>();
            if (track)
            {
                track.sprite = track.sprite ?? LoadBattleSprite("battle_card_status_base_520x62");
                track.color = Color.white;
            }
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
            StopPrimaryValueAnimation();
            if (hitRoutine != null) StopCoroutine(hitRoutine);
            hitRoutine = null;
            if (restPositionCached) ((RectTransform)transform).localPosition = restLocalPosition;
        }

        private void OnDestroy()
        {
            StopPrimaryValueAnimation();
            DOTween.Kill(this);
            ReleaseMaterials();
        }
    }

}

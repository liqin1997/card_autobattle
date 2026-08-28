# 战斗界面切图清单

本批素材按 `BattleUI_ArtSpec_1080x1920.md` 的分层规范输出，所有 PNG 均为独立文件，不把运行时扫光、弹道、跳字和粒子烘焙进卡牌素材。

## 输出目录

`Assets/Art/BattleUI/Cutouts/`

## 文件

| 文件 | 尺寸 | 用途 |
|---|---:|---|
| `battle_card_frame_common_576x368.png` | 576×368 | 2×公共卡牌外框，中心透明，Unity 九宫格或整图使用 |
| `battle_card_art_*_544x336.png` | 544×336 | 2×卡牌插画区，对应运行时 272×168 |
| `battle_card_tag_badge_196x76.png` | 196×76 | 2×右上标签徽章，运行时 98×38 |
| `battle_card_status_base_520x62.png` | 520×62 | 2×底部状态槽，运行时 260×31 |
| `battle_card_status_hp_fill_300x34.png` | 300×34 | 2×生命/护盾填充示例 |
| `battle_card_status_charge_fill_300x34.png` | 300×34 | 2×充能/CD 填充示例 |

插画文件命名如下：

- `summon_skull`：召唤/敌方首领
- `defense_shield`：防御单位
- `sword_relic`：剑系单位/技能
- `thunder_cannon`：雷电单位/技能
- `gun_rifle`：枪械单位/技能
- `hero_swordsman`：主角

## 接入注意

- 运行时单卡仍是 `288×184 px`，外框不得因为血条或技能状态改变尺寸。
- 插画显示区为 `272×168 px`；导入后禁止再次按卡牌整体比例拉伸。
- 标签、数值、状态填充由 Unity UI/Shader 生成；本批素材只提供公共视觉层。
- `BattleUI_Cutouts_ContactSheet.png` 仅用于人工检查切图对应关系，不作为运行时资源。
- 由于源图是用户提供的完整卡牌图，本批插画按固定矩形插画区裁切，未对角色轮廓做 AI 重绘或改形。

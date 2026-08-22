# 卡牌自动战斗框架扩展改造任务

## 1. 任务目标

在保留当前原型玩法、探索流程、整备界面和现有卡牌行为的前提下，把战斗部分从集中式原型代码调整为可扩展的、数据驱动的战斗框架。

本次只做框架调整，不实现“剑意”“万剑归心”或其他新卡牌技能，不制作新弹道和新 VFX。

改造后的框架需要支持后续实现：

- 可叠层、可消费、可监听变化的状态/Buff。
- 条件判断与多个效果组合。
- 延迟命中、多段命中、追踪弹道等具有战斗时序的技能。
- 表现与战斗逻辑隔离。
- 暂停、倍速和跳过表现时，战斗结果仍保持一致。
- 后续逐步将硬编码卡牌迁移为配置资产。

## 2. 当前工程与重点文件

Unity 工程：

```text
C:\Users\LQ\Desktop\demo\demo\card_autobattle
```

当前战斗逻辑主要集中在：

```text
Assets/Scripts/Prototype/PrototypeGameFlowController.cs
```

当前相关文件：

```text
Assets/Scripts/Prototype/CardDefinition.cs
Assets/Scripts/Prototype/CardEffectValueResolver.cs
Assets/Scripts/Prototype/BattleCardView.cs
Assets/Scripts/Battle/BattleSceneView.cs
Assets/Scripts/Battle/BattleActorView.cs
Assets/Scripts/Preparation/PreparationBoardController.cs
Assets/Scripts/Preparation/PreparationSlotUI.cs
```

## 3. 不得扩大范围

本次不要：

- 实现剑意、万剑归心或其他具体新技能。
- 重做探索、商店、整备、拖拽、UI 路由或角色成长系统。
- 改变现有卡牌的数值与实际战斗结果。
- 更换 Spine、URP 或现有美术资源。
- 制作正式弹道、VFX 或音效资源。
- 为每张卡创建一个专属 MonoBehaviour。
- 一次性删除旧 `CardEffectKind` 兼容路径。
- 依赖弹道碰撞或动画回调决定战斗伤害。
- 让 ScriptableObject 保存局内可变状态。

如果迁移中发现无关缺陷，只记录，不顺带重构。

## 4. 核心设计约束

### 4.1 战斗逻辑是唯一权威

生命、护盾、Buff、层数、CD、目标、随机结果和命中时间都由纯战斗逻辑决定。

表现层只能读取战斗事件并播放视觉效果，不得反向决定：

- 是否命中。
- 造成多少伤害。
- 是否附加 Buff。
- 是否暴击。
- 是否死亡。
- 下一步战斗逻辑何时执行。

### 4.2 数据、运行时状态、表现分离

```text
Definition/Config = 静态配置
Runtime           = 单场战斗可变状态
Effect            = 战斗规则
BattleEvent       = 已发生或计划发生的逻辑事实
Presentation      = 对 BattleEvent 的视觉表达
```

### 4.3 使用统一战斗时间

不得由不同 MonoBehaviour 各自用 `Time.deltaTime` 推进核心战斗状态。

建立统一 `BattleClock` 或等价时间源：

```csharp
BattleDeltaTime = UnityUnscaledDeltaTime * Speed;
BattleTime += BattleDeltaTime;
```

暂停时 `BattleDeltaTime = 0`。倍速只改变战斗时间推进速度。

逻辑调度与表现播放都读取同一速度状态，但表现丢失、关闭或跳过时不能影响逻辑。

## 5. 目标目录结构

名称可在不改变职责的前提下微调：

```text
Assets/Scripts/Battle/Core
    BattleController.cs
    BattleClock.cs
    BattleContext.cs
    BattleScheduler.cs
    BattleSide.cs

Assets/Scripts/Battle/Units
    BattleUnitRuntime.cs
    BattleStatsRuntime.cs

Assets/Scripts/Battle/Cards
    CardRuntime.cs
    GridPosition.cs
    BattleCardDefinition.cs

Assets/Scripts/Battle/Effects
    BattleEffect.cs
    EffectContext.cs
    EffectSequence.cs
    DamageEffect.cs
    HealEffect.cs
    ShieldEffect.cs
    ApplyBuffEffect.cs
    ModifyCooldownEffect.cs

Assets/Scripts/Battle/Conditions
    BattleCondition.cs
    EffectCondition.cs

Assets/Scripts/Battle/Buffs
    BuffDefinition.cs
    BuffRuntime.cs
    BuffController.cs
    BuffStackPolicy.cs

Assets/Scripts/Battle/Events
    BattleEvent.cs
    BattleEventStream.cs
    BattleEventType.cs
    PresentationEvent.cs

Assets/Scripts/Battle/Presentation
    BattlePresentationController.cs
    BattlePresentationConfig.cs
    ProjectilePresentationConfig.cs
```

## 6. 必须建立的运行时模型

### 6.1 BattleUnitRuntime

不得依赖 GameObject 才能进行战斗计算。

至少包含：

```csharp
public sealed class BattleUnitRuntime
{
    public int RuntimeId { get; }
    public BattleSide Side { get; }
    public float MaxHealth { get; }
    public float Health { get; private set; }
    public float Shield { get; private set; }
    public BuffController Buffs { get; }
    public IReadOnlyList<CardRuntime> Cards { get; }
}
```

伤害、治疗和护盾变更必须通过明确方法执行，并产生结构化战斗事件。

### 6.2 CardRuntime

至少包含：

```csharp
public sealed class CardRuntime
{
    public int RuntimeId { get; }
    public BattleCardDefinition Definition { get; }
    public BattleUnitRuntime Owner { get; }
    public GridPosition Position { get; }
    public float CooldownRemaining { get; private set; }
    public bool Enabled { get; set; }
}
```

当前 `Index` 在迁移入口转换成 `GridPosition`：

```csharp
X = index % 3;
Y = index / 3;
```

不要让 `CardRuntime` 持有 `BattleCardView`。

### 6.3 EffectContext

效果执行统一使用上下文，不允许继续依赖大量 `bool enemy` 参数：

```csharp
public sealed class EffectContext
{
    public BattleContext Battle { get; init; }
    public CardRuntime SourceCard { get; init; }
    public BattleUnitRuntime SourceUnit { get; init; }
    public BattleUnitRuntime PrimaryTarget { get; init; }
    public IReadOnlyList<BattleUnitRuntime> Targets { get; init; }
    public int TriggerId { get; init; }
    public int ChainDepth { get; init; }
    public int ConsumedStackCount { get; set; }
}
```

后续字段允许扩展，但不要将 Animator、ParticleSystem、Transform 或 View 引用放入逻辑上下文。

## 7. 效果系统

### 7.1 组合式效果

建立统一效果抽象：

```csharp
public abstract class BattleEffect : ScriptableObject
{
    public abstract void Execute(EffectContext context);
}
```

一张卡可以顺序执行多个效果：

```text
Conditions[]
Effects[]
```

第一阶段只需要迁移当前已有的基础效果能力：

- Damage
- Heal
- Shield
- ApplyBurn/ApplyPoison（通过 BuffController）
- ModifyCooldown
- 当前邻接加成与光环计算

不要在本次实现新技能。

### 7.2 条件系统

建立可组合条件接口，但本次只需提供框架和最基础实现：

```csharp
public abstract class BattleCondition : ScriptableObject
{
    public abstract bool Evaluate(EffectContext context);
}
```

至少预留：

- Buff 层数条件。
- 生命比例条件。
- 卡牌标签条件。
- 相邻卡牌条件。

无需创建剑意条件资产。

### 7.3 旧卡牌兼容适配器

现有 `PrototypeCardCatalog`、`CardDefinition` 和 `CardEffectKind` 暂时保留。

建立兼容适配层，将旧定义转换为新运行时定义或新效果序列。迁移期允许使用一个集中式 `LegacyCardEffectAdapter`，但新核心不得直接依赖 UI 类型。

目标是先保证现有卡牌行为不变，再逐步将旧卡牌迁移为 ScriptableObject 配置，而不是本次强制一次性改完全部内容资产。

## 8. Buff 系统

建立独立 Buff 模型：

```csharp
public abstract class BuffDefinition : ScriptableObject
{
    public string BuffId;
    public int MaxStacks;
    public float Duration;
    public BuffStackPolicy StackPolicy;
}

public sealed class BuffRuntime
{
    public BuffDefinition Definition { get; }
    public BattleUnitRuntime Owner { get; }
    public BattleUnitRuntime Source { get; }
    public int Stacks { get; private set; }
    public float RemainingDuration { get; private set; }
}
```

`BuffController` 至少提供：

```csharp
GetStacks(buffId)
HasStacks(buffId, minimum)
AddStacks(buffId, amount, source)
RemoveStacks(buffId, amount)
ConsumeAllStacks(buffId)
RemoveBuff(buffId)
Tick(deltaTime)
```

每次层数变化必须发出事件，事件至少包含：

```text
OwnerRuntimeId
BuffId
PreviousStacks
CurrentStacks
ChangeAmount
SourceRuntimeId
BattleTime
```

燃烧与中毒应迁移到 Buff 系统；迁移完成后不得继续以 `playerBurn`、`enemyBurn`、`playerPoison`、`enemyPoison` 四个字段作为权威数据。

## 9. 战斗调度与时序

建立 `BattleScheduler` 或等价模块，使用战斗时间安排逻辑动作：

```csharp
Schedule(executeAtBattleTime, action)
ScheduleAfter(delay, action)
Tick(currentBattleTime)
```

要求：

- 同一时间的动作必须有稳定的执行顺序。
- 不依赖 Coroutine、DOTween 完成回调、Animator Event 或 Projectile 碰撞执行核心结算。
- 延迟动作必须保存运行时 ID，不长期持有已销毁 View。
- 战斗结束后取消未执行动作或根据明确规则忽略。
- 倍速改变现实耗时，不改变逻辑事件顺序与结果。

当前已有卡牌可以继续使用 `impactDelay = 0`，因此本次框架调整不应改变它们的结算时机。

## 10. 结构化战斗事件

不要只发送 `enemySource + CardEffectKind + amount`。

建立只读事件数据，至少覆盖：

```text
BattleStarted
CardTriggered
EffectStarted
ProjectileRequested
DamageApplied
HealApplied
ShieldChanged
BuffApplied
BuffStacksChanged
BuffRemoved
UnitDefeated
BattleEnded
```

通用字段建议：

```csharp
public abstract record BattleEvent
{
    public long Sequence { get; init; }
    public float BattleTime { get; init; }
    public int TriggerId { get; init; }
    public int SourceUnitId { get; init; }
    public int TargetUnitId { get; init; }
}
```

伤害事件必须同时提供请求值与最终结果，例如：

```text
RequestedAmount
ShieldAbsorbed
HealthDamage
RemainingHealth
```

表现层只订阅或读取事件流。

## 11. 表现层与弹道预留

建立 `BattlePresentationController`，负责把逻辑 RuntimeId 映射到 View/Transform。

逻辑层可以发出 `ProjectileRequested`，其中保存：

```text
PresentationId
SourceUnitId
TargetUnitId
LaunchBattleTime
ImpactBattleTime
Count
TriggerId
```

本次不实现正式弹道，只建立接口和一个安全的空实现/即时表现适配器。

关键要求：

- Projectile GameObject 只负责视觉移动。
- Projectile 不直接调用伤害、Buff 或战斗控制器。
- Projectile 丢失或对象池不足时，逻辑结算仍正常发生。
- 表现晚于逻辑时可以追赶、缩短或跳过。
- 战斗跳过时可以清理表现对象，但不得遗漏逻辑结算。

将现有 `BattleSceneView.PlayCardActivation()` 改为由结构化事件驱动，或者保留为兼容表现适配器。不要让新核心直接调用该 View 方法。

## 12. 确定性与随机数

在 `BattleContext` 中提供战斗专用随机数源，并允许传入种子。

禁止效果代码直接使用：

```text
UnityEngine.Random
Environment.TickCount
System.Random 的临时实例
```

所有会影响战斗结果的随机选择必须由战斗上下文产生。表现层随机抖动、粒子变化不进入战斗随机序列。

## 13. PrototypeGameFlowController 的拆分边界

`PrototypeGameFlowController` 可以继续负责：

- 探索/整备/战斗阶段切换。
- 创建战斗配置。
- 启动和结束一场战斗。
- 根据战斗结果调用 `ExplorationSessionController`。
- 显示现有流程 UI。

它不应继续负责：

- 每张卡的 CD Tick。
- `CardEffectKind` 大 switch 的最终效果执行。
- 玩家/敌人的 HP、Shield、Burn、Poison 权威状态。
- 直接计算伤害、治疗或 Buff Tick。
- 根据技能种类判断播放哪种攻击表现。

## 14. 推荐迁移顺序

必须采用可编译的小步迁移，避免一次性重写：

1. 新增 BattleClock、BattleContext、BattleUnitRuntime、CardRuntime 和 GridPosition。
2. 新增 BattleEventStream，并让新核心产生基础事件。
3. 将 HP、Shield 和伤害/治疗结算迁入 BattleUnitRuntime。
4. 将卡牌 CD Tick 迁入独立 BattleController。
5. 建立旧 `CardEffectKind` 到新效果的兼容适配器。
6. 让现有 View 通过表现适配器消费结构化事件。
7. 新增 BuffController，并迁移 Burn、Poison。
8. 新增 BattleScheduler，当前效果默认零延迟。
9. 添加条件与效果组合接口。
10. 删除 `PrototypeGameFlowController` 中已经失去职责的战斗字段和方法。

每完成一步都应保证工程可编译；不要先删除旧逻辑再尝试补齐新逻辑。

## 15. 测试要求

优先添加 EditMode 纯逻辑测试，不依赖场景和 VFX。

至少验证：

### 15.1 基础结算

- 护盾先于生命承伤。
- 治疗不超过最大生命。
- CD 到期只触发一次并正确重置。
- 3×3 相邻关系与当前规则一致。

### 15.2 Buff

- 添加层数、减少层数、全部消费结果正确。
- 层数变化事件数据正确。
- Burn/Poison 迁移后与当前版本的 Tick 结果一致。

### 15.3 时序和倍速

使用相同种子和相同战斗配置：

```text
速度 1x 跑完
速度 2x 跑完
速度 4x 跑完
无表现层跑完
```

最终结果必须一致：

- 胜负一致。
- 最终生命与护盾一致。
- Buff 最终状态一致。
- 战斗事件的逻辑顺序一致。
- 影响战斗结果的随机选择一致。

### 15.4 回归

- 现有探索难度 1 可以进入战斗并返回整备。
- 现有卡牌行为与数值不发生有意变化。
- 战斗 HUD、卡牌 CD、角色攻击/受击和结果面板仍能工作。

## 16. 性能与生命周期要求

- 战斗逻辑避免每张卡、每个 Buff 各自创建 MonoBehaviour Update。
- 由 BattleController 统一 Tick Runtime。
- 战斗事件避免长期保存 Unity Object 引用。
- 订阅必须在战斗销毁或 View 禁用时解除。
- 本次只预留 Projectile/VFX 对象池接口，不要求完整对象池实现。
- 不进行未经测量的大规模性能优化。

## 17. 交付要求

执行完成后提供：

1. 修改/新增文件清单。
2. 新战斗执行链说明。
3. 旧卡牌兼容方式说明。
4. 哪些旧字段和 switch 已经移除，哪些仍暂时保留。
5. EditMode/PlayMode 测试结果。
6. Unity Console 编译错误与警告检查结果。
7. 尚未迁移内容和后续风险清单。

不要仅提交接口空壳。核心应实际接管现有战斗的 HP、Shield、CD、基础效果和 Burn/Poison 状态结算，同时保持现有玩法可运行。

## 18. 最终验收标准

满足以下条件才算完成：

- `PrototypeGameFlowController` 不再拥有核心战斗状态和逐卡效果 switch 的主要职责。
- 战斗可以在没有 `BattleSceneView` 的情况下完整运行并得到结果。
- Runtime 不引用 View、Transform、Animator、ParticleSystem。
- 表现层不调用伤害、治疗、Buff 或 CD 结算。
- 伤害、治疗、护盾、Buff 和卡牌触发都有结构化事件。
- Buff 支持通用层数查询、变化和全部消费。
- Scheduler 支持基于 BattleTime 的延迟逻辑结算。
- 1x、2x、4x 和无表现运行的战斗结果一致。
- 当前卡牌、探索流程和基本战斗画面保持可用。
- 未实现任何剑意或万剑归心专属逻辑。


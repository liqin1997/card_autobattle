using UnityEngine;

namespace CardAutobattle.Battle
{
    /// <summary>Single source of battle time. It is deliberately independent from presentation objects.</summary>
    public sealed class BattleClock
    {
        public float BattleTime { get; private set; }
        public float Speed { get; private set; } = 1f;
        public bool Paused { get; private set; }
        public float BattleDeltaTime { get; private set; }

        public void SetSpeed(float speed) => Speed = Mathf.Max(0f, speed);
        public void SetPaused(bool paused) => Paused = paused;

        public float Advance(float unityUnscaledDeltaTime)
        {
            BattleDeltaTime = Paused ? 0f : Mathf.Max(0f, unityUnscaledDeltaTime) * Speed;
            BattleTime += BattleDeltaTime;
            return BattleDeltaTime;
        }
    }
}

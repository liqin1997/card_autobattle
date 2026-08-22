using UnityEngine;

namespace CardAutobattle.Battle
{
    [CreateAssetMenu(menuName = "Card Autobattle/Battle Presentation Config")]
    public sealed class BattlePresentationConfig : ScriptableObject
    {
        public bool PlayCardActivations = true;
        public bool RequestProjectiles = true;
        public float CatchUpDuration = .08f;
    }

    [CreateAssetMenu(menuName = "Card Autobattle/Projectile Presentation Config")]
    public sealed class ProjectilePresentationConfig : ScriptableObject
    {
        public string PresentationId = "instant";
        public float TravelDuration = .12f;
    }
}

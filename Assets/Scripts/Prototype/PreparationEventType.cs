using UnityEngine;

namespace CardAutobattle.Prototype
{
    public enum PreparationEventType
    {
        None = 0,
        Merchant = 1,
        EnhanceSlot = 2,
        CardWorkshop = 3,
        WastelandCamp = 4,
        TacticalProtocol = 5,
        RuinsExploration = 6,
        EquipmentCache = 7
    }

    public static class PreparationEventSequence
    {
        public static PreparationEventType GetEvent(int eventIndex)
        {
            if (eventIndex <= 0)
                return PreparationEventType.Merchant;
            if (eventIndex == 1)
                return PreparationEventType.EnhanceSlot;

            var value = Random.Range(1, 8);
            return (PreparationEventType)value;
        }
    }
}

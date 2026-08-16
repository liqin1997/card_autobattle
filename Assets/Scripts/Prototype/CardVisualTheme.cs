using System;
using System.Collections.Generic;
using UnityEngine;

namespace CardAutobattle.Prototype
{
    [Serializable]
    public sealed class CardArtEntry
    {
        public string CardId;
        public Sprite Artwork;
        [Range(.6f, 1.4f)] public float Scale = 1f;
        public Vector2 Offset;
    }

    [CreateAssetMenu(fileName = "CardVisualTheme", menuName = "Card Autobattle/Card Visual Theme")]
    public sealed class CardVisualTheme : ScriptableObject
    {
        [Header("Quality Frames")]
        [SerializeField] private Sprite levelOneFrame;
        [SerializeField] private Sprite levelTwoFrame;
        [SerializeField] private Sprite levelThreeFrame;

        [Header("Card Artwork")]
        [SerializeField] private List<CardArtEntry> cardArtwork = new();

        private Dictionary<string, Sprite> lookup;
        private static CardVisualTheme instance;

        public static CardVisualTheme Instance
        {
            get
            {
                if (!instance)
                    instance = Resources.Load<CardVisualTheme>("CardVisualTheme");
                return instance;
            }
        }

        public Sprite GetFrame(int level)
        {
            return level <= 1 ? levelOneFrame : level == 2 ? levelTwoFrame : levelThreeFrame;
        }

        public Sprite GetArtwork(string cardId)
        {
            return GetArtEntry(cardId)?.Artwork;
        }

        public CardArtEntry GetArtEntry(string cardId)
        {
            if (lookup == null)
            {
                lookup = new Dictionary<string, Sprite>(StringComparer.Ordinal);
                foreach (var entry in cardArtwork)
                    if (entry != null && !string.IsNullOrEmpty(entry.CardId) && entry.Artwork)
                        lookup[entry.CardId] = entry.Artwork;
            }

            if (cardId == null || !lookup.ContainsKey(cardId))
                return null;
            foreach (var entry in cardArtwork)
                if (entry != null && entry.CardId == cardId)
                    return entry;
            return null;
        }

#if UNITY_EDITOR
        public void EditorConfigure(Sprite one, Sprite two, Sprite three, List<CardArtEntry> artwork)
        {
            levelOneFrame = one;
            levelTwoFrame = two;
            levelThreeFrame = three;
            cardArtwork = artwork ?? new List<CardArtEntry>();
            lookup = null;
        }
#endif
    }
}

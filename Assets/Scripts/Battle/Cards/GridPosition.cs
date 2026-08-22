using System;

namespace CardAutobattle.Battle
{
    [Serializable]
    public readonly struct GridPosition : IEquatable<GridPosition>
    {
        public readonly int X;
        public readonly int Y;

        public GridPosition(int x, int y) { X = x; Y = y; }
        public int Index => Y * 3 + X;
        public bool Equals(GridPosition other) => X == other.X && Y == other.Y;
        public override bool Equals(object obj) => obj is GridPosition other && Equals(other);
        public override int GetHashCode() => (X * 397) ^ Y;
        public override string ToString() => $"({X},{Y})";

        public static GridPosition FromIndex(int index) => new(index % 3, index / 3);
        public static bool AreAdjacent(GridPosition a, GridPosition b) =>
            Math.Abs(a.X - b.X) + Math.Abs(a.Y - b.Y) == 1;
    }
}

using System.Collections.Generic;
using UnityEngine;

namespace CardAutobattle.UI
{
    public sealed class UIObjectPool<T> where T : Component
    {
        private readonly T prefab;
        private readonly Transform inactiveRoot;
        private readonly Stack<T> inactive = new();

        public UIObjectPool(T sourcePrefab, Transform poolRoot)
        {
            prefab = sourcePrefab;
            inactiveRoot = poolRoot;
        }

        public T Rent(Transform parent)
        {
            var item = inactive.Count > 0 ? inactive.Pop() : Object.Instantiate(prefab);
            item.transform.SetParent(parent, false);
            item.gameObject.SetActive(true);
            return item;
        }

        public void Return(T item)
        {
            if (!item)
                return;
            item.gameObject.SetActive(false);
            item.transform.SetParent(inactiveRoot, false);
            inactive.Push(item);
        }

        public void Clear()
        {
            while (inactive.Count > 0)
            {
                var item = inactive.Pop();
                if (item)
                    Object.Destroy(item.gameObject);
            }
        }
    }
}

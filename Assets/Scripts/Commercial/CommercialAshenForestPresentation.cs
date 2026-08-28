using System;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    // Scene sprites and paths follow persistent discoveries; no per-node Update or canvas rebuilds.
    public sealed class CommercialAshenForestPresentation : MonoBehaviour
    {
        [Serializable] public sealed class Location
        {
            public string NodeId;
            public GameObject Root;
            public SpriteRenderer Landmark;
        }
        public Location[] Locations = Array.Empty<Location>();
        private CommercialPrototypeController controller;
        private float nextRefresh;
        private int revision = -1;
        private void LateUpdate()
        {
            if (Time.unscaledTime < nextRefresh) return;
            nextRefresh = Time.unscaledTime + .25f;
            if (!controller) controller = GetComponentInParent<CommercialPrototypeController>();
            if (!controller || controller.State == null) return;
            var state = controller.State;
            var changed = state.World.RevealedNodes.Count * 1000 + state.World.CompletedNodes.Count;
            if (revision == changed) return;
            revision = changed;
            foreach (var item in Locations)
            {
                if (!item.Root) continue;
                item.Root.SetActive(state.World.RevealedNodes.Contains(item.NodeId) && CommercialAshenForest.Accessible(state, item.NodeId));
                if (item.Landmark && item.NodeId == "af_bridge") item.Landmark.color = CommercialAshenForest.Done(state, item.NodeId)
                    ? Color.white : new Color(.48f, .39f, .32f);
            }
        }
    }
}

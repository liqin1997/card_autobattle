using System;
using UnityEngine;

namespace CardAutobattle.UI
{
    public enum UIScreenId
    {
        None = 0,
        MainHub = 10,
        ScavengerDraft = 15,
        Preparation = 20
    }

    public enum UIWindowState
    {
        Closed,
        Opening,
        Open,
        Closing
    }

    [Serializable]
    public sealed class UIScreenRegistration
    {
        public UIScreenId Id;
        public GameObject Prefab;
        public bool KeepAlive = true;
    }
}

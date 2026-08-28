using System;
using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class CommercialAshenForestBuilder
    {
        [MenuItem("Tools/Card Autobattle/Install Ashen Forest Sample")]
        public static void Install()
        {
            var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
            if (Application.isPlaying || scene.path != "Assets/Scenes/CommercialVerticalSlice.unity")
                throw new InvalidOperationException("Open CommercialVerticalSlice outside Play Mode first.");
            var view = UnityEngine.Object.FindObjectOfType<CommercialWorldMapView>(true);
            if (!view || !view.MapRoot) throw new InvalidOperationException("Existing world map required.");
            if (!view.MapRoot.Find("AshenForestSample"))
            {
                foreach (var t in view.MapRoot.GetComponentsInChildren<Transform>(true))
                    if (t.name == "Biome_0" || t.name == "Region_1" || t.name.StartsWith("Forest_0_") ||
                        new[] { "Ridge_0", "QuestCamp_0", "Elite_0", "Boss_0", "Treasure_0" }.Contains(t.name))
                    { Undo.RecordObject(t.gameObject, "Archive old forest layout"); t.gameObject.SetActive(false); }
                var group = new GameObject("AshenForestSample"); Undo.RegisterCreatedObjectUndo(group, "Build forest sample");
                group.transform.SetParent(view.MapRoot, false); group.layer = view.MapRoot.gameObject.layer;
                var layer = view.FogRenderer.gameObject.layer;
                var material = view.FogRenderer.sharedMaterial;
                var presentation = group.AddComponent<CommercialAshenForestPresentation>();
                var entries = new List<CommercialAshenForestPresentation.Location>();
                Sprite(group.transform, "ForestFloor", "2_Trees_Mountains/Earth_green.png", new Vector2(-12, 1), new Vector2(28, 32), 7);
                // A continuous river and a visible bridge explain the second exploration gate.
                Sprite(group.transform, "ForestRiver", "2_Trees_Mountains/River_0.png", new Vector2(-7, 3), new Vector2(14, 12), 8);
                for (var i = 0; i < 24; i++)
                {
                    var x = -23 + i % 4 * 6f; var y = -12 + i / 4 * 5f;
                    Sprite(group.transform, "Trees_" + i, "2_Trees_Mountains/Dark_forest_little.png", new Vector2(x, y), new Vector2(3.5f, 3.1f), 12);
                }
                foreach (var node in CommercialAshenForest.Config.Nodes)
                {
                    var location = new GameObject("Location_" + node.Id); location.transform.SetParent(group.transform, false); location.layer = layer;
                    var path = node.Id == "af_bridge" ? "3_Buildings/bridge_wood.png" : node.Id == "boss_1" ? "2_Trees_Mountains/Dark_trees.png" : node.Sprite;
                    var landmark = Sprite(location.transform, "Landmark", path, new Vector2(node.X, node.Y),
                        node.Id == "boss_1" ? new Vector2(4, 4) : new Vector2(2.8f, 2.5f), 35);
                    var predecessor = node.Id switch
                    {
                        "main_1" or "chest_1" or "af_scout" => "quest_1",
                        "elite_1" or "af_cache" => "af_scout",
                        "af_mine" or "af_bridge" => "elite_1",
                        "af_orecache" => "af_mine",
                        "af_hollow" or "af_relic" => "af_bridge",
                        "af_sealed" => "af_relic", "boss_1" => "af_hollow", "af_exit" => "boss_1", _ => null
                    };
                    if (predecessor != null)
                    {
                        var from = CommercialAshenForest.Node(predecessor);
                        var a = new Vector2(from.X, from.Y); var b = new Vector2(node.X, node.Y);
                        var count = Mathf.CeilToInt(Vector2.Distance(a, b) / .65f);
                        // Shared SpriteRenderer material; small map-route dashes avoid custom materials per node.
                        for (var d = 1; d < count; d++)
                        {
                            var dash = Sprite(location.transform, "Path_" + d, "2_Trees_Mountains/Earth_sand.png", Vector2.Lerp(a, b, d / (float)count), new Vector2(.32f, .22f), 9);
                            dash.color = new Color(.7f, .57f, .34f, .75f);
                        }
                    }
                    entries.Add(new CommercialAshenForestPresentation.Location { NodeId = node.Id, Root = location, Landmark = landmark });
                    location.SetActive(node.Step == 0);
                }
                presentation.Locations = entries.ToArray();
                SpriteRenderer Sprite(Transform parent, string name, string asset, Vector2 pos, Vector2 size, int order)
                {
                    var sprite = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/FantasyMapCreator_2/" + asset);
                    if (!sprite) throw new InvalidOperationException("Missing map art " + asset);
                    var go = new GameObject(name, typeof(SpriteRenderer)); go.transform.SetParent(parent, false); go.layer = layer;
                    go.transform.localPosition = pos; go.transform.localScale = new Vector3(size.x / sprite.bounds.size.x, size.y / sprite.bounds.size.y, 1);
                    var r = go.GetComponent<SpriteRenderer>(); r.sprite = sprite; r.sharedMaterial = material; r.sortingOrder = order; return r;
                }
            }
            // More room for story, progress and guaranteed rewards without shrinking touch targets.
            Fit((RectTransform)view.DetailPanel.transform, new Vector2(.025f, .127f), new Vector2(.975f, .47f));
            Fit(view.DetailTitle.rectTransform, new Vector2(.04f, .87f), new Vector2(.82f, .98f));
            Fit(view.DetailBody.rectTransform, new Vector2(.04f, .20f), new Vector2(.96f, .86f));
            view.DetailBody.fontSize = 27; view.DetailBody.resizeTextForBestFit = false;
            Fit((RectTransform)view.ActionButton.transform, new Vector2(.04f, .025f), new Vector2(.68f, .17f));
            Fit((RectTransform)view.TrackButton.transform, new Vector2(.71f, .025f), new Vector2(.96f, .17f));
            Fit(view.DetailPanel.transform.Find("CloseWorldDetail") as RectTransform, new Vector2(.86f, .87f), new Vector2(.98f, .98f));
            view.Header.fontSize = 28;
            view.FullPage.SetActive(false);
            EditorUtility.SetDirty(view);
            const string prefabs = "Assets/Resources/Commercial/Prefabs/";
            PrefabUtility.SaveAsPrefabAsset(view.MapRoot.gameObject, prefabs + "PF_WorldMap_SpriteWorld.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.FullPage, prefabs + "PF_Screen_WorldMap.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.gameObject, prefabs + "PF_CommercialGameRoot.prefab");
            EditorSceneManager.MarkSceneDirty(scene); EditorSceneManager.SaveScene(scene);
        }
        private static void Fit(RectTransform r, Vector2 min, Vector2 max)
        { Undo.RecordObject(r, "Forest task layout"); r.anchorMin = min; r.anchorMax = max; r.offsetMin = r.offsetMax = Vector2.zero; }
    }
}

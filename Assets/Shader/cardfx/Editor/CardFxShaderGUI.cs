using UnityEditor;
using UnityEngine;

public sealed class CardFxShaderGUI : ShaderGUI
{
    private static bool baseExpanded = true;
    private static bool distortExpanded = true;
    private static readonly bool[] effectExpanded = { true, true, true, true };
    private static bool stormExpanded = true;
    private static bool advancedExpanded;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        serializedObjectUpdate(materialEditor);

        baseExpanded = EditorGUILayout.BeginFoldoutHeaderGroup(baseExpanded, "Base");
        if (baseExpanded)
        {
            DrawTextureWithScaleOffset(materialEditor, properties, "_MainTex", "Raw");
            DrawTextureWithScaleOffset(materialEditor, properties, "_MaskTex", "Mask");
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(2f);
        distortExpanded = EditorGUILayout.BeginFoldoutHeaderGroup(distortExpanded, "Distort");
        if (distortExpanded)
            DrawDistort(materialEditor, properties);
        EditorGUILayout.EndFoldoutHeaderGroup();

        for (var layer = 1; layer <= 4; layer++)
        {
            EditorGUILayout.Space(2f);
            effectExpanded[layer - 1] = EditorGUILayout.BeginFoldoutHeaderGroup(
                effectExpanded[layer - 1], $"Effect {layer}");
            if (effectExpanded[layer - 1])
                DrawEffect(materialEditor, properties, layer);
            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        EditorGUILayout.Space(2f);
        stormExpanded = EditorGUILayout.BeginFoldoutHeaderGroup(stormExpanded, "Storm Timing");
        if (stormExpanded)
        {
            DrawProperty(materialEditor, properties, "_StormEnabled");
            if (Find(properties, "_StormEnabled").floatValue > 0.5f)
            {
                EditorGUI.indentLevel++;
                DrawProperty(materialEditor, properties, "_StormPeriod");
                DrawProperty(materialEditor, properties, "_StormDuration");
                DrawProperty(materialEditor, properties, "_StormPhase");
                DrawProperty(materialEditor, properties, "_StormCloudStrength");
                DrawProperty(materialEditor, properties, "_StormIdleMinimum");
                DrawProperty(materialEditor, properties, "_StormIdleSharpness");
                DrawProperty(materialEditor, properties, "_StormRevealSoftness");
                EditorGUI.indentLevel--;
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        EditorGUILayout.Space(2f);
        advancedExpanded = EditorGUILayout.BeginFoldoutHeaderGroup(advancedExpanded, "Advanced");
        if (advancedExpanded)
        {
            DrawProperty(materialEditor, properties, "_AnimationSpeed");
            DrawProperty(materialEditor, properties, "_TimeOffset");
            DrawProperty(materialEditor, properties, "_UseUV1");
            DrawProperty(materialEditor, properties, "_UseUIAlphaClip");
            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        materialEditor.serializedObject.ApplyModifiedProperties();
    }

    private static void serializedObjectUpdate(MaterialEditor materialEditor)
    {
        materialEditor.serializedObject.Update();
    }

    private static void DrawDistort(MaterialEditor editor, MaterialProperty[] properties)
    {
        DrawProperty(editor, properties, "_DistortEnabled");
        if (Find(properties, "_DistortEnabled").floatValue < 0.5f)
            return;

        EditorGUI.indentLevel++;
        DrawProperty(editor, properties, "_DisturbAmpX");
        DrawProperty(editor, properties, "_DisturbAmpY");
        DrawTextureWithScaleOffset(editor, properties, "_DistortTex", "Tex");
        DrawProperty(editor, properties, "_DistortColor");
        DrawTransformProperties(editor, properties, "_Distort");
        DrawProperty(editor, properties, "_DistortChannel");
        DrawProperty(editor, properties, "_DistortBlendMode");
        EditorGUI.indentLevel--;
    }

    private static void DrawEffect(MaterialEditor editor, MaterialProperty[] properties, int layer)
    {
        var prefix = $"_Effect{layer}";
        DrawProperty(editor, properties, prefix + "Enabled");
        if (Find(properties, prefix + "Enabled").floatValue < 0.5f)
            return;

        EditorGUI.indentLevel++;
        DrawTextureWithScaleOffset(editor, properties, prefix + "Tex", "Tex");
        DrawProperty(editor, properties, prefix + "Color");
        DrawTransformProperties(editor, properties, prefix);
        DrawProperty(editor, properties, prefix + "Channel");
        DrawProperty(editor, properties, prefix + "BlendMode");
        EditorGUI.indentLevel--;
    }

    private static void DrawTransformProperties(
        MaterialEditor editor,
        MaterialProperty[] properties,
        string prefix)
    {
        DrawProperty(editor, properties, prefix + "Angle");
        DrawProperty(editor, properties, prefix + "Polar");
        DrawProperty(editor, properties, prefix + "PanX");
        DrawProperty(editor, properties, prefix + "PanY");
        DrawProperty(editor, properties, prefix + "RotV");
        DrawProperty(editor, properties, prefix + "Spiral");
        DrawProperty(editor, properties, prefix + "FlashV");
    }

    private static void DrawTextureWithScaleOffset(
        MaterialEditor editor,
        MaterialProperty[] properties,
        string propertyName,
        string label)
    {
        var property = Find(properties, propertyName);
        editor.TexturePropertySingleLine(new GUIContent(label), property);
        editor.TextureScaleOffsetProperty(property);
    }

    private static void DrawProperty(
        MaterialEditor editor,
        MaterialProperty[] properties,
        string propertyName)
    {
        var property = Find(properties, propertyName);
        editor.ShaderProperty(property, property.displayName);
    }

    private static MaterialProperty Find(MaterialProperty[] properties, string propertyName)
    {
        return FindProperty(propertyName, properties);
    }
}

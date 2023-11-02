using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;



public class GrabTexRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent m_RenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }
    public Settings m_Settings = new Settings();
    public GrabPass m_GrabPass;
    public override void Create()
    {
        m_GrabPass = new GrabPass(m_Settings.m_RenderPassEvent);
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_GrabPass);
    }
    public class GrabPass : ScriptableRenderPass
    {
        private static readonly string s_RenderTag = " Distort Source Texture";
        // private RenderTargetIdentifier m_BlurTex;
        private RenderTargetIdentifier m_Temp;
        public GrabPass(RenderPassEvent evt)
        {
            renderPassEvent = evt;

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get(s_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
        public void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTargetIdentifier sourceRT = renderingData.cameraData.renderer.cameraColorTarget;
            RenderTextureDescriptor inRTDesc = renderingData.cameraData.cameraTargetDescriptor;
            inRTDesc.depthBufferBits = 0;

            var width = (int)(inRTDesc.width);
            var height = (int)(inRTDesc.height);
            int tempID = Shader.PropertyToID("_GrabTemp");
            // int blurTexID = Shader.PropertyToID("_DistortTex");
            cmd.GetTemporaryRT(tempID, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.DefaultHDR);
            // cmd.GetTemporaryRT(blurTexID, inRTDesc);

            // m_BlurTex = new RenderTargetIdentifier(blurTexID);
            m_Temp = new RenderTargetIdentifier(tempID);

            cmd.Blit(sourceRT, m_Temp);
            cmd.Blit(m_Temp, sourceRT);
        }
    }
}

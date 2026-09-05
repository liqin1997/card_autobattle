using UnityEngine;

namespace CardAutobattle.Commercial
{
    /// <summary>
    /// The sole moving node for one projectile presentation.  A prefab's visual body,
    /// particles and TrailRenderers are children of this actor; none of them owns an
    /// independent flight path.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class CommercialProjectileActor : MonoBehaviour
    {
        public Transform BodyAnchor { get; private set; }
        public GameObject Visual { get; private set; }

        private ParticleSystem[] particles;
        private TrailRenderer[] trails;
        private ParticleSystem main02;

        public void Bind(GameObject visual, bool main02IsBody)
        {
            Visual = visual;
            visual.transform.SetParent(transform, false);
            particles = visual.GetComponentsInChildren<ParticleSystem>(true);
            trails = visual.GetComponentsInChildren<TrailRenderer>(true);
            main02 = null;
            foreach (var particle in particles)
            {
                if (particle.name == "main02") { main02 = particle; break; }
            }
            BodyAnchor = main02IsBody && main02 ? main02.transform : visual.transform;
        }

        public void ConfigureAllyGloryBody()
        {
            if (!main02) return;
            // Imported Glory prefab rotates its particle container by 180 degrees for its
            // original scene. The actor owns flight orientation, so remove that baked turn.
            if (main02.transform.parent) main02.transform.parent.localRotation = Quaternion.identity;
            var main = main02.main;
            main.loop = false;
            main.simulationSpace = ParticleSystemSimulationSpace.Local;
            main.startDelay = new ParticleSystem.MinMaxCurve(0f);
            main.startLifetime = new ParticleSystem.MinMaxCurve(.85f);
            main.startSize = new ParticleSystem.MinMaxCurve(5f);
            main.startSpeed = new ParticleSystem.MinMaxCurve(0f);
            main.maxParticles = 1;
            var shape = main02.shape; shape.enabled = false;
            var velocity = main02.velocityOverLifetime; velocity.enabled = false;
            var force = main02.forceOverLifetime; force.enabled = false;
            var noise = main02.noise; noise.enabled = false;
            var inherit = main02.inheritVelocity; inherit.enabled = false;
            var limit = main02.limitVelocityOverLifetime; limit.enabled = false;
            var external = main02.externalForces; external.enabled = false;
            var emission = main02.emission;
            emission.enabled = false;
            main02.transform.localScale *= 2f;

            foreach (var particle in particles)
            {
                if (particle.name != "sparks") continue;
                particle.transform.localPosition = main02.transform.localPosition;
                var sparksMain = particle.main;
                sparksMain.simulationSpace = ParticleSystemSimulationSpace.Local;
                sparksMain.startDelay = new ParticleSystem.MinMaxCurve(0f);
                sparksMain.startLifetime = new ParticleSystem.MinMaxCurve(.25f, .42f);
                sparksMain.startSize = new ParticleSystem.MinMaxCurve(2f, 2.5f);
                sparksMain.maxParticles = 30;
                var sparksEmission = particle.emission;
                sparksEmission.enabled = true;
                sparksEmission.rateOverTime = new ParticleSystem.MinMaxCurve(18f);
                particle.transform.localScale *= 4f;
            }
            foreach (var trail in trails)
            {
                trail.transform.localPosition = main02.transform.localPosition;
                trail.transform.localRotation = Quaternion.identity;
            }
        }

        public void Begin()
        {
            foreach (var trail in trails)
            {
                trail.emitting = false;
                trail.Clear();
                trail.emitting = true;
            }
            foreach (var particle in particles)
            {
                particle.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
                particle.Play(true);
            }
            if (!main02) return;
            // main02 is the projectile entity. Explicitly emitting it after the actor
            // reaches its launch position prevents a stale pooled particle at the old point.
            main02.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
            main02.Play(false);
            main02.Emit(1);
        }

        public void StopTrailEmission()
        {
            foreach (var trail in trails) trail.emitting = false;
        }

        public void ResetActor()
        {
            foreach (var particle in particles)
                particle.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
            foreach (var trail in trails)
            {
                trail.emitting = false;
                trail.Clear();
            }
        }
    }
}

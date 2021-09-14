
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class ObjectAngleManager: UdonSharpBehaviour
{
    [SerializeField] private Transform axis;
    [SerializeField] private Transform trackingObject;
    [SerializeField] private int objectInitialPhase = 0;
    [SerializeField] private float netNormalizedAngle;
    private float normalizedAngle;
    private Matrix4x4 WorldToAxisMatrix;
    private const float tau = Mathf.PI * 2.0f;
    public float getModuloAngle(int m)
    {
        return Mathf.Floor(Mathf.Repeat(netNormalizedAngle, m)) + normalizedAngle;
    }

    private float getFloatAngle(Vector3 p)
    {
        return Mathf.Repeat(Mathf.Atan2(p.z, p.x) / tau, 1);
    }

    private float getNormalizedAngle(float previousNetNormalizedAngle, float currentNormalizedAngle)
    {
        var currentNetNormalizedAngleCandidate_0 = Mathf.Floor(previousNetNormalizedAngle) + currentNormalizedAngle;
        var currentNetNormalizedAngleCandidate_m = currentNetNormalizedAngleCandidate_0 - 1;
        var currentNetNormalizedAngleCandidate_p = currentNetNormalizedAngleCandidate_0 + 1;
        var diff0 = Mathf.Abs(currentNetNormalizedAngleCandidate_0 - previousNetNormalizedAngle);
        var diffm = Mathf.Abs(currentNetNormalizedAngleCandidate_m - previousNetNormalizedAngle);
        var diffp = Mathf.Abs(currentNetNormalizedAngleCandidate_p - previousNetNormalizedAngle);
        if (diffm < diff0)
            return currentNetNormalizedAngleCandidate_m;
        else if (diff0 < diffp)
            return currentNetNormalizedAngleCandidate_0;
        else
            return currentNetNormalizedAngleCandidate_p;
    }

    void Start()
    {
        if (trackingObject == null) trackingObject = this.transform;
        WorldToAxisMatrix = axis.localToWorldMatrix.inverse;
        normalizedAngle = getFloatAngle(WorldToAxisMatrix.MultiplyPoint3x4(trackingObject.position));
        netNormalizedAngle = normalizedAngle + objectInitialPhase;
    }

    public void Update()
    {
        if (!axis.gameObject.isStatic) WorldToAxisMatrix = axis.localToWorldMatrix.inverse;
        if (!trackingObject.gameObject.isStatic)
        {
            var objectWorldPos = trackingObject.position;
            var objectAxisPos = WorldToAxisMatrix.MultiplyPoint3x4(objectWorldPos);
            normalizedAngle = getFloatAngle(objectAxisPos);
            netNormalizedAngle = getNormalizedAngle(netNormalizedAngle, normalizedAngle);
        }
    }
}
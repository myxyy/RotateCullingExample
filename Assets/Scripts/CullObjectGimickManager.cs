
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class CullObjectGimickManager: UdonSharpBehaviour
{
    [SerializeField] private ObjectAngleManager playerAngle;
    [SerializeField] private ObjectAngleManager objectAngle;
    [SerializeField] private Transform axis;
    [SerializeField] private int period = 1;
    private Material material;
    void Start()
    {
        if (objectAngle == null) objectAngle = this.GetComponent<ObjectAngleManager>();
        if (period < 1) period = 1;
        material = this.GetComponent<MeshRenderer>().material;
        material.SetFloat("_Period", period);
    }
    void Update()
    {
        material.SetFloat("_PlayerAngle", playerAngle.getModuloAngle(period));
        material.SetFloat("_ObjectAngle", objectAngle.getModuloAngle(period));
        Matrix4x4 worldToAxis = axis.transform.localToWorldMatrix.inverse;
        material.SetMatrix("_WorldToAxis", worldToAxis);
    }
}
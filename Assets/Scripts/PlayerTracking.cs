
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class PlayerTracking : UdonSharpBehaviour
{
    public void Update()
    {
        Vector3 position = Networking.LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position;
        Quaternion rotation = Networking.LocalPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).rotation;
        this.gameObject.transform.position = position;
        this.gameObject.transform.rotation = rotation;
    }
}
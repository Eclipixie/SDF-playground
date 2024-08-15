using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Cinemachine;
using UnityEditor;
using TMPro;

public class Player : MonoBehaviour {
    [SerializeField] float speed = 5;
    [SerializeField] MeshRenderer viewport;
    [SerializeField] Transform camTF;
    [SerializeField] float camDist = 5;
    [SerializeField] CinemachineVirtualCamera cVCam;
    [SerializeField] Transform viewPortTF;

    CinemachineComponentBase compBase;
    MaterialPropertyBlock mpb;
    readonly int target = 144;

    float currentTime = 0f;

    void Awake() {
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = target;

        compBase = cVCam.GetCinemachineComponent(CinemachineCore.Stage.Body);
    }

    // Start is called before the first frame update
    void Start() {
        mpb = new MaterialPropertyBlock();
        viewport.SetPropertyBlock(mpb);
    }

    // Update is called once per frame
    void Update() {
        if (Application.targetFrameRate != target)
            Application.targetFrameRate = target;

        Vector3 controlDir = new(
            Convert.ToInt32(Input.GetKey(KeyCode.D)) - Convert.ToInt32(Input.GetKey(KeyCode.A)),
            Convert.ToInt32(Input.GetKey(KeyCode.E)) - Convert.ToInt32(Input.GetKey(KeyCode.Q)),
            Convert.ToInt32(Input.GetKey(KeyCode.W)) - Convert.ToInt32(Input.GetKey(KeyCode.S)));

        controlDir.y = 0;

        controlDir.Normalize();

        Vector3 moveDir =
            controlDir.x * camTF.right
            + controlDir.y * camTF.up
            + controlDir.z * camTF.forward;

        moveDir.y = 0;

        moveDir.Normalize();

        transform.position += speed * Time.deltaTime * moveDir;

        Vector2 mouseControls = new(-Input.GetAxisRaw("Mouse Y"), Input.GetAxisRaw("Mouse X"));

        Vector3 newRot = transform.rotation.eulerAngles + (Vector3)mouseControls;

        float highBound = 85;
        float lowBound = 360 - highBound;

        if (newRot.x > highBound && newRot.x < lowBound) {
            if (newRot.x <= (highBound + lowBound) * 0.5)
                newRot.x = highBound;
            else
                newRot.x = lowBound;
        }

        transform.rotation = Quaternion.Euler(newRot);

        viewport.GetPropertyBlock(mpb);
        mpb.SetVector("_Position", camTF.transform.position);
        mpb.SetVector("_Rotation", new Vector4(
            camTF.rotation.x,
            camTF.rotation.y,
            camTF.rotation.z,
            camTF.rotation.w));
        mpb.SetVector("_PlayerLight", new Vector4(
            transform.position.x,
            transform.position.y,
            transform.position.z,
            0));
        mpb.SetFloat("_GTime", currentTime);
        viewport.SetPropertyBlock(mpb);

        // if (compBase is Cinemachine3rdPersonFollow) {
        //     (compBase as Cinemachine3rdPersonFollow).CameraDistance = camDist;
        // }
        // else {
        //     Debug.Log("failed");
        // }

        viewPortTF.localPosition = new Vector3(0, 0, camDist + 1);
        viewPortTF.localScale = new Vector3(2 * (camDist + 1), 2 * (camDist + 1), 1);

        map._PlayerLight = transform.position;

        currentTime += Time.deltaTime;
    }
}

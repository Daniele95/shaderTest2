using UnityEngine;
using System.Collections;



public class GameLogic : MonoBehaviour {

    public GameObject sprite;
    float bar = 0;
    float initPos;
    int IsPlayed;
    float StartTime;

    // Use this for initialization
    void Start () {
        initPos = transform.position.y;
        IsPlayed = 0;
        StartTime = 0;
    }

    // Update is called once per frame
    void Update () {
        float Height = Mathf.Abs(initPos - transform.position.y);
        Height /= 3;
        transform.Translate(0, -(float)0.01, 0);
        Shader.SetGlobalFloat("_BallHeight", Height);
        Shader.SetGlobalFloat("_StartTime", StartTime);
        if (IsPlayed==1)
            StartTime += Time.deltaTime;
    }

    void OnMouseOver()
    {
        if (Input.GetMouseButtonDown(0) && IsPlayed == 0 )
        {
            IsPlayed = 1;
            Shader.SetGlobalInt("_IsPlayed", IsPlayed);
            Instantiate(sprite,transform.position,transform.rotation);
            AudioSource audio = GetComponent<AudioSource>();
            audio.Play();
        }
    }
}

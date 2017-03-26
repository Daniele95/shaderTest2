using UnityEngine;
using System.Collections;


public class CueBehavior : MonoBehaviour {

	public GameObject quad;
	
    void Start () {
			quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
			quad.transform.position = transform.position;
			quad.transform.localScale += new Vector3(2F, 2F, 2F);
    }

    void Update () {
			transform.Translate(0, -(float)0.006, 0);
			quad.transform.Translate(0, -(float)0.006, 0);
    }

}

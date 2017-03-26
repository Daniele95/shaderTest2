using UnityEngine;
using System;
using System.Collections.Generic;

public class PostPro : MonoBehaviour {
	

	public Material postProMat;
	GameObject cue1;
	GameObject cue2;
    Camera cam;


 	[Space(10)]
 	[Header("Global")]
	[Range(0f,1f)]
	public float friction ;
 	[Space(20)]
 	
 	[Header("Interaction between particles")]
 	[Space(10)]

	[Range(0f,1f)]
	public float force;
	[Range(0f,1f)]
	public float meanDist;
	[Range(0f,1f)]
	public float forceRadius;

 	[Space(10)]
	[Header("Forces driving the particles from one cue to the next one")]
 	[Space(20)]

	[Range(0f,1f)]
	public float driveForce;
	[Range(0f,1f)]	
	public float driveMeanDist;
	//[Range(0f,1f)]	
	//public float driveForceRadius;
 	[Space(20)]


	
	const int N = 20; //particelle	
	const int M = 4; //centri attrazione

	Vector2[] particles = new Vector2[N]; // position of particle i
	Vector2[] v = new Vector2[N];
	Vector2[] a  = new Vector2[N];	
	
	Vector2 [ , ] F = new Vector2 [ N , N ];
	Vector2 [ , ] mainF = new Vector2 [ N , M ];

	
	void getCues() {
		GameObject[] cues = GameObject.FindGameObjectsWithTag("Cue");
		cue1 = cues[0];
		cue2 = cues[1];
	}

	Vector2 rand(float x, float y) {
		Vector2 rand;
		rand.x = UnityEngine.Random.Range(0f,x);
		rand.y = UnityEngine.Random.Range(0f,y);
		return rand;
	}

	void setParams() {

		friction *= 5f;

		//force *= 0.0005f;
		meanDist *= 0.0002f;
		forceRadius *= 1.2f;

		driveForce *= 30f;
		driveMeanDist *= 2f;
		//driveForceRadius *= .2f;

	}
	float interaction(float x, float d, float x0, float a) {
		float e1 = (float)Math.Exp(-a*(x-x0));
		float e2 = (float)Math.Exp(-2f*a*(x-x0));
		float force = e2-4f*e1+1f;
		return a * d * force;
	}
	float field(float x, float d, float x0) {
		return d /(1f+(float)Math.Pow(x/x0,2f));
	}
    void Start () {
		postProMat.SetInt ( "N" , N );		
		cam = GetComponent<Camera>();
		getCues();
		setParams();
		
		// initial conditions	
		
		for ( int i = 0 ; i < N ; i++ ) {
			a[i] = new Vector2(0,0);
			v[i] = new Vector2(0,0);
				
			// dove nascono le particelle
			particles[i] =  rand(.1f,.1f);
			
			// le metto lungo alcune linee
			if( i < N/2 ) particles[i] -=  new Vector2(i/7f,i/7f)*(float)Math.Sqrt(i);
			if( i >= N/2 ) particles[i] -= new Vector2(.1f+.7f*(i-N/2),-.1f+.7f*(i-N/2));
		}
			
    }


	void Update() {
		
	// Uniforms for hyperbolas: cue pos & size
		
		// Get first and second cue's position
		Vector3 cue1Pos = cam.WorldToScreenPoint ( cue1.transform.position );
		postProMat.SetVector ( "cue1Pos" , new Vector2 ( cue1Pos.x , cue1Pos.y ) );
		Vector3 cue2Pos = cam.WorldToScreenPoint ( cue2.transform.position );
		postProMat.SetVector ( "cue2Pos" , new Vector2 ( cue2Pos.x , cue2Pos.y ) );
		
		// Get first and second cue's size
		Vector3 cue1Size = cue1.GetComponent<CueBehavior>( ).quad.transform.localScale;
		Vector3 cue2Size = cue2.GetComponent<CueBehavior>( ).quad.transform.localScale;
		postProMat.SetVector ( "cue1Size" , new Vector2 ( cue1Size.x , cue1Size.y ) );
		postProMat.SetVector( "cue2Size" , new Vector2 ( cue2Size.x ,cue2Size.y ) );
		
		

		// origin for the particles
		Vector2 corner1 = cue1.transform.position + cue1Size/2f;
		Vector2 corner2 = cue2.transform.position - cue2Size/2f;


	// Uniforms for particles: main direction
		Vector2 quadPos = cue2.transform.position ;

		
		for( int i= 0; i < N; i++ ) {

			// ciclo sui centri d'attrazione
			for( int j = 0 ; j < M; j++ ) {
				Vector2 center = corner2;
				if (j<2) center[j] += 1.5f;
				else { 
					center = corner1;
					center[j-2] -= 1.5f;
				}
				Debug.DrawRay(center,new Vector2(.1f,0f));
				Vector2 dir = center - (corner1 + particles[i]);
				float dist = dir.magnitude;
				dir.Normalize();
				mainF [i,j] = field(dist, driveForce, driveMeanDist) * dir;
				if (j>=2) mainF [i,j] /= 10f;
				Debug.DrawRay(corner1+ particles[i], mainF[i,j]/mainF[i,j].magnitude) ;
			}
				
	// Uniforms for particles: all particles interaction

			for( int j = i; j < N; j++ ) {
				
				if( j != i )	{	
				
					Vector2 dir = particles[j]-particles[i];
					float dist = dir.magnitude;
					dir.Normalize();
					F[i,j] = interaction(dist, force, meanDist, forceRadius) * dir;
					Debug.DrawRay(corner1+ particles[i], -particles[i]+particles[j]);
				}
				
				else F[i,j] = new Vector2(0f,0f);
				F[j,i] = -F[i,j];
				
			}
		}
				
		
		Vector4[] screenParticles = new Vector4[N];

		// viene calcolata la posizione della particella	
		for( int i= 0; i < N; i++ ) {
			a[i] = new Vector2(0f,0f);
			a[i] += - friction * v[i];	// attrito
			
			for( int j = 0; j < N; j++ ) {
				a[i] += F[i,j];
			}
			
			for( int j = 0; j < M; j++ ) {
				a[i] += mainF[i,j];
			}

			v[i] += a[i]*Time.deltaTime; // aggiungere dt
			particles[i] += v[i]*Time.deltaTime;  // aggiungere dt

			screenParticles[i] = (Vector4)cam.WorldToScreenPoint(corner1+particles[i]);
			// distrugge particelle
			if((corner1+particles[i]-(Vector2)cue1.transform.position)[0]<1f) screenParticles[i] = new Vector2(0f,0f);
			if((corner1+particles[i]-corner2)[0]>.2f || (corner1+particles[i]-corner2)[1]>.2f) screenParticles[i] = new Vector2(0f,0f);
		}
		
		// passo allo shader la pos assoluta sullo schermo
		postProMat.SetVectorArray ( "particles" , screenParticles );
	}
	
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit( source, destination, postProMat, 0 );
    }
	
}

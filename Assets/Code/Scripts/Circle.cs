using UnityEngine;
using UnityEngine.UI;

public class Circle : MonoBehaviour
{
	[SerializeField] private GameObject[] prefabs;
	[SerializeField] private Color[]      colors;
	[SerializeField] private GameObject   backgroundPrefab;
	[SerializeField] private float        circleRadius;


	private void Awake()
	{
		Debug.Assert(colors.Length == prefabs.Length,
					 "Please make sure the colors array is the same size as the prefabs array. :D");

		var segmentAngle        = 360.0f / prefabs.Length;
		var oneHalfSegmentAngle = segmentAngle * 0.5f;
		var segmentPercent      = 1.0f / prefabs.Length;

		for( int segmentIndex = 0;
			 segmentIndex < prefabs.Length;
			 segmentIndex++ )
		{
			var segment = Instantiate( backgroundPrefab, transform );
			var image   = backgroundPrefab.GetComponent<Image>();
			image.fillAmount = segmentPercent;
			image.color      = colors[segmentIndex];
			segment.transform.Rotate( Vector3.forward,
									  (segmentAngle * segmentIndex) + oneHalfSegmentAngle);

		}

		for( int segmentIndex = 0;
			 segmentIndex < prefabs.Length;
			 segmentIndex++ )
		{
			var segmentT = segmentPercent * Mathf.PI * 2.0f * segmentIndex;
			Vector3 point = new Vector3(Mathf.Cos(segmentT), Mathf.Sin(segmentT), 0.0f) * circleRadius;

			Instantiate( prefabs[segmentIndex],
						 point + transform.position,
						 Quaternion.identity,
						 transform );
		}
	}
}

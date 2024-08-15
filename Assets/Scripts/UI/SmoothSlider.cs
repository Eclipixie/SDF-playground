using UnityEngine;
using UnityEngine.UI;

public class SmoothSlider : MonoBehaviour {
    Slider slider;
    Image sliderFill;

    [SerializeField] float smoothing = 0.1f;

    float goal;

    float vel = 0;

    [SerializeField] Color emptyColor;
    [SerializeField] Color fullColor;

    private void Awake() {
        slider = GetComponent<Slider>();
        sliderFill = slider.fillRect.GetComponent<Image>();
    }

    private void Update() {
        slider.value = Mathf.SmoothDamp(slider.value, goal, ref vel, smoothing);

        sliderFill.color = Color.Lerp(emptyColor, fullColor, slider.value);
    }

    public void SetValue(float value) => goal = value;

    public float GetValue() => goal;
}

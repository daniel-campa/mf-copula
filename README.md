<a id="readme-top"></a>

# Path Generation and Evaluation in Video Games

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/github_username/repo_name">
    <img src="img/schola.png" alt="Logo">
  </a>

<!-- <h3 align="center">Path Generation and Evaluation in Video Games</h3> -->

  <p align="center">
    This repository contains the code used to generate and evaluate synthetic navigation paths via a nonparametric statistical approach (model-free transformation + copula). Below are the key visual results produced by the code.
    <br />
    <a href="https://arxiv.org/"><strong>Read the full paper »</strong></a>
  </p>
</div>



---

## Results

### Human vs Raycast vs Synthetic Human

<figure>
  <img src="img/frontiers-experiments.png" alt="Human vs Raycast vs Synthetic Human" />
  <figcaption><strong>Figure 1.</strong> The original data consists of human (green) and raycast-based RL
agents (red) navigating through a 2D obstacle course, with obstacles shown
as black diamonds [14]. Our synthetically generated human trajectories (blue)
are visually more human-like than the raycast agents. We analytically show
this in Section VI using statistical hypothesis testing.</figcaption>
</figure>

### Schola Plugin: Original and Synthetic Paths

<figure>
  <img src="img/schola-experiments.png" alt="Original and Synthetic paths from Schola plugin" />
  <figcaption><strong>Figure 7.</strong> Original and Synthetic paths from Schola plugin. Note that original paths are shown in red and blue, starting from stars and ending at diamonds.
Synthetic paths for each case are shown in green (5 for each agent). We see that increasing b or λ increases the variance in the synthetic paths and they
transition from being strongly overfitted to strongly underfitted from left to right. While the middle subplot produces most of its variance towards the end of
the synthetic trajectories, the right subplot produces high variance even at the start. This is likely the reason for the increased CT value observed in Table I.</figcaption>
</figure>

### Schola Sample Frames

<figure>
  <img src="img/schola-frames.png" alt="Sample frames from a synthetic episode" />
  <figcaption><strong>Figure 8.</strong> Three frames from a synthetically generated episode based on the Schola Tag example. This figure demonstrates that temporal properties are preserved
during our generation process. The trajectories progress over time in a manner that matches the behavior of the paths in the original dataset.</figcaption>
</figure>

### Navigation Turing Test: Original and Synthetic 3D Paths

<figure>
  <img src="img/ntt-experiments.png" alt="Synthetic paths for the NTT dataset" />
  <figcaption><strong>Figure 9.</strong> 50 NTT synthetic generated paths from 3 different parameter sets. In this case too we see that increasing bor λincreases the variance in the synthetic
paths and they transition from being strongly overfitted to strongly underfitted from left to right.</figcaption>
</figure>

---

<!-- ## Repository Structure

```
├── frontiers/        # Preprocessing script for 
├── HNTT/             # Generation & evaluation scripts
├── img/              # Exported figures (PNG) used in this README
├── notebooks/        # Exported figures (PNG) used in this README
├── schola/           # Exported figures (PNG) used in this README
├── synthetic/        # Exported figures (PNG) used in this README
├── .gitignore        # Exported figures (PNG) used in this README
├── LICENSE           # Exported figures (PNG) used in this README
├── README.md         # This file
└── requirements.txt  # Python dependencies
``` -->

## Requirements

* Python >= 3.8

Install with:

```bash
pip install -r requirements.txt
```

<!-- ## Usage

Generate synthetic paths and evaluation results:

```bash
# Example: Generate Schola paths with medium variance
python scripts/generate_paths.py --dataset schola --bandwidth 10 --scale 10

# Example: Run the three-sample hypothesis test for NTT data
python scripts/evaluate_paths.py --dataset ntt --bandwidth 5 --scale 50
```

Detailed options are available with:

```bash
python scripts/generate_paths.py --help
``` -->

<!-- CONTACT -->
## Contact

Daniel Campa - [LinkedIn](https://www.linkedin.com/in/danielcampa/) - dc00039@mix.wvu.edu

<!-- Project Link: [https://github.com/github_username/repo_name](https://github.com/github_username/repo_name) -->



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* Dr. Mehdi Saeedi -- Principal Staff, AMD Research
* Dr. Ian Colbert -- Technical Staff, AMD Research
* Dr. Srinjoy Das -- Assistant Professor, Department of Mathematical and Data Sciences, West Virginia University

<p align="right">(<a href="#readme-top">back to top</a>)</p>

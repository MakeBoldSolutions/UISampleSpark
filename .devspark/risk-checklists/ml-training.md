# ML Training Risk Checklist

## Reproducibility

- [ ] **Deterministic seeds set across libraries** — Python, NumPy, framework, CUDA where supported
- [ ] **Environment pinned** — `requirements.txt`/`uv.lock`/conda env exported; container digest captured
- [ ] **Data version pinned** — dataset hash / snapshot id / DVC pointer; immutable splits

## Data Integrity

- [ ] **No leakage between train / val / test** (grouped splits where rows share identity)
- [ ] **Eval set isolated from any prompt/feature engineering iteration loop**
- [ ] **Class balance, distribution drift, and outliers profiled** before training

## Train / Serve Skew

- [ ] **Feature transforms shared between training and inference** (single library / spec)
- [ ] **Tokenizer / preprocessor version pinned with model artifact**
- [ ] **Inference-time input validation matches training assumptions**

## Artifact & Eval

- [ ] **Model artifact versioned with training config, dataset id, metrics** — e.g., MLflow, W&B, Vertex
- [ ] **Hold-out eval reported alongside training metrics**; loss-only is insufficient
- [ ] **Bias / fairness / safety evals where domain warrants**
- [ ] **Rollback to prior model artifact is one command**

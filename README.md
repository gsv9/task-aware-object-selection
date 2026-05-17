# Task-Aware Object Selection Pipeline

A task-aware affordance reasoning pipeline developed for the **DVCon India Design Contest – Stage 2A**.

The system combines:
- object detection,
- semantic task reasoning,
- affordance-aware filtering,
- contextual spatial reasoning,
- and task-specific object ranking

to identify the most suitable object in an image for performing a given task.

---

# Problem Statement

Given:
- an input image
- a natural language task query

the pipeline selects the most relevant object in the scene that can be used to perform the specified task.

Example queries:
- *What should I use to serve wine?*
- *What should I use to pour sugar?*
- *What should I use to smear butter?*
- *What should I use to extinguish a fire?*

---

# Pipeline Architecture

The proposed system consists of six major stages:

## 1. Object Detection
- YOLO v26 Nano detector
- Detects candidate objects in the input image
- Outputs:
  - object labels
  - confidence scores
  - bounding boxes

---

## 2. Semantic Task Encoding
- DistilBERT sentence embeddings
- Encodes:
  - task query
  - detected object labels

---

## 3. Cosine Similarity Filtering
- Computes semantic similarity between:
  - task embedding
  - object embeddings

- Generates task relevance scores.

---

## 4. Affordance-Aware Priors

Task-specific prior boosts are applied to objects that are likely to satisfy the task affordance.

Examples:
- wine glass → serve wine
- spoon → get lemon out of tea
- chair → sit comfortably
- knife → smear butter

---

## 5. Spatial Context Reasoning
- Lightweight contextual reasoning module
- Computes spatial proximity scores using object center distances
- Encourages contextually relevant object relationships

---

## 6. Final Ranking

Final object score:

```text
Final Score =
0.97 × task_score +
0.03 × spatial_score +
0.05 × detector_confidence
```

Highest ranked valid object is selected.

---

# Project Structure

```text
task-aware-object-selection/
│
├── src/
│   ├── detector.py
│   ├── encoder.py
│   ├── filter.py
│   ├── reasoner.py
│   ├── pipeline.py
│   ├── evaluate.py
│   ├── visualize.py
│   ├── metrics.py
│   ├── data_types.py
│   └── main.py
│
├── results/
│   ├── final_metrics.txt
│   ├── metrics.csv
│   └── evaluation_results_v8.txt
│
├── final_demo_images/
│
├── requirements.txt
├── prepare_dataset.py
├── organize_demo_images.py
└── README.md
```

---

# Installation

Clone the repository:

```bash
git clone https://github.com/gsv9/task-aware-object-selection.git
cd task-aware-object-selection
```

Install dependencies:

```bash
pip install -r requirements.txt
```

---

# Running the Pipeline

## Run inference

```bash
cd src
python main.py
```

---

## Save evaluation logs

```bash
python main.py > ../results/evaluation_results_v8.txt
```

---

## Run evaluation

```bash
python evaluate.py
```

---

# Evaluation Results

## Final Metrics

| Metric | Value |
|---|---|
| Overall Accuracy | 59.29% |
| Average Latency | 0.1214 sec |
| FPS | 8.24 |

---

# Task-Wise Accuracy

| Task | Accuracy |
|---|---|
| step_on_something | 100% |
| sit_comfortably | 100% |
| place_flowers | 100% |
| get_lemon_out_of_tea | 100% |
| pour_sugar | 100% |
| extinguish_fire | 100% |
| smear_butter | 95% |
| serve_wine | 80% |
| get_potatoes_out_of_fire | 55% |

---

# Qualitative Outputs

Example qualitative outputs are available in:

```text
final_demo_images/
```

These include:
- successful affordance selections,
- contextual reasoning examples,
- rejection cases.

---

# Limitations

The current implementation relies primarily on COCO object classes.

Some affordance-oriented tasks show lower accuracy due to:
- limited detector vocabulary,
- absence of affordance annotations in COCO,
- missing tool-centric object classes.

Examples of missing classes:
- shovel
- watering can
- bottle opener
- carpet beater

---

# Future Work

Future extensions include:
- custom affordance-aware dataset collection,
- YOLO fine-tuning with additional tool classes,
- generalized affordance embeddings,
- graph-based contextual reasoning,
- FPGA acceleration for ranking and similarity computation.

---

# Technologies Used

- Python
- YOLO v26 Nano
- DistilBERT
- Sentence Transformers
- OpenCV
- NumPy
- scikit-learn

---

# Authors

DVCon India Design Contest Team

GitHub Repository:

https://github.com/gsv9/task-aware-object-selection
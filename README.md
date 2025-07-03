# Meta-Analysis Project

A comprehensive meta-analysis of AI-based semantic segmentation models for agricultural land-use and land-cover (LULC) mapping. This repository centralizes all project resources—data, scripts, documentation, figures—and supports fully reproducible research.

---

## Project Structure

```
├── docs/                    # Documentation (protocol, PRISMA flowchart, methodology)
│   └── protocol.md          # Systematic review protocol
├── meta/                    # Core meta-analysis code
│   ├── assets/              # Final figures and plots (PDF, PNG)
│   ├── meta.r               # R script for 3-level multilevel meta-analysis
│   └── metanalise.ipynb     # Jupyter notebook: data prep, heatmaps, moderator analysis
├── paper/                   # Manuscript materials
│   ├── quality/             # Quality checklists (Excel)
│   └── refs/                # Bibliographic references (BibTeX)
│       └── search_result/   # Result of search string of each base (BibTeX)
├── sheets/                  # Data spreadsheets (Excel)
│   ├── meta_analysis_v4.xlsx# Main dataset: study IDs, metrics, sample sizes
│   └── other_tables.xlsx    # Supplementary tables: criteria, scores
├── LICENSE                  # MIT License
└── README.md                # Main guide file
```

---

## Getting Started

1. **Clone the repository**

   ```bash
   git clone https://github.com/MatMB115/lulc-segmentation-materials
   cd lulc-segmentation-materials
   ```
2. **Install dependencies**

   * **R (≥ 4.5.1)**:

     ```r
     install.packages(c("metafor", "readxl", "dplyr", "janitor", "stringr", "tibble"))
     ```
   * **Python (≥ 3.10)**:

     ```bash
     pip install pandas matplotlib openpyxl jupyter
     ```
3. **Prepare data**

   * Place processed Excel files in `sheets/`.
  
4. **Run the analysis**

   * **R script**:

     ```bash
     Rscript meta/meta.r
     ```
   * **Jupyter Notebook**:

     ```bash
     jupyter notebook meta/metanalise.ipynb
     ```
5. **Inspect outputs**

   * Figures and tables must are saved to `assets/`.
   * Logs and intermediate files (if any) appear in `meta/`.

---

## Available Scripts and Notebooks

| Language | Path                    | Description                                                                                   |
| -------- | ----------------------- | --------------------------------------------------------------------------------------------- |
| R        | `meta/meta.r`           | Multilevel (3-level) meta-analysis of F1-scores with forest, funnel plots and meta-regression |
| Python   | `meta/metanalise.ipynb` | Interactive notebook: data import, preprocessing and heatmaps                                 |

---

## Data

* **Main dataset (`sheets/meta_analysis_v4.xlsx`)**:

  * `geral` sheet: cleaned study-level data (IDs, metrics, sample sizes, moderators).
* **Supplementary tables (`sheets/other_tables.xlsx`)**:

  * Inclusion/exclusion criteria, quality assessment scores.

---

## Documentation

* **Protocol**: `docs/protocol.md`
* **PRISMA Diagram**: `docs/figures/prisma_flowchart.pdf`
* **Methodology Appendix**: detailed meta-analysis procedure and formulas.

---

## Methodological Overview of Included Studies

| Study (Year)                   | Original Task (as stated by authors)                    | **Task Group**<br>(meta-analysis)       | Data Source / Sensor                        | Proposed Model / Key Idea                     | Comparative Models / Variants                | Validation Highlights                              |
| ------------------------------ | ------------------------------------------------------- | --------------------------------------- | ------------------------------------------- | --------------------------------------------- | -------------------------------------------- | -------------------------------------------------- |
| **De Bem et al. 2021**         | Irrigated-rice detection with SAR time series           | *Paddy-rice Detection / Classification* | Sentinel-1 SAR (VV, VH)                     | U-Net / LinkNet (12 backbones)                | Backbone & polarisation variants             | Polarisation vs. backbone performance              |
| **Li et al. 2025**             | Cropland segmentation in mountainous terrain (ultra-HR) | *Field-boundary Segmentation*           | Ultra-HR RGB (Google Earth, multi-temporal) | Cascade DeepLab-Net (cascaded DeepLabV3+)     | U-Net, PSPNet, DeepLabV3+                    | Ablation (SRM, SAM, RM); architecture benchmarks   |
| **Rauf et al. 2022**           | Pixel-level rice-variety classification                 | *Paddy-rice Detection / Classification* | Multispectral optical                       | 2-D CNN (VGG-like) + spectral unmixing        | Same CNN without unmixing                    | Impact of unmixing on metrics                      |
| **Sun et al. 2024**            | Rapeseed-field mapping (phenology aware)                | *Crop-type Classification*              | Sentinel-2 time series                      | — (DL benchmark)                              | U-Net, PSPNet, DeepLabV3+ (ResNet 18–101)    | Early vs. peak flowering performance               |
| **de Albuquerque et al. 2020** | Centre-pivot irrigation detection                       | *Centre-pivot Mapping*                  | Landsat-8 optical                           | — (U-Net, Deep ResUNet, SharpMask)            | idem                                         | Dry vs. rainy season; reconstruction stride study  |
| **Lu et al. 2022**             | Field-boundary extraction from high-res imagery         | *Field-boundary Segmentation*           | Gaofen-2 (4-band MS)                        | DASFNet (dual attention + multi-scale fusion) | SegNet, ResUNet, PSPNet…                     | Ablation (ResABlock, scSE, APPM); model benchmarks |
| **Xu et al. 2020**             | Cropland-area extraction preserving detail              | *Field-boundary Segmentation*           | Landsat 30 m (band combos)                  | HRU-Net (enhanced skips)                      | U-Net, U-Net++, Random Forest                | Spectral-band combos; ML baseline                  |
| **Xue et al. 2023**            | Lychee/longan crop segmentation (hyperspectral)         | *Crop-type Classification*              | Zhuhai-1 hyperspectral                      | MRSALENet (spatial–spectral attention)        | —                                            | Multi-scale analysis with hyperspectral input      |
| **Ayushi et al. 2024**         | Crop-type classification in smallholder farms           | *Crop-type Classification*              | Sentinel-2 time series                      | U-Net workflow                                | RF, CatBoost, KNN, FCN, SegNet               | ML × DL comparison; temporal-series input          |
| **Graf et al. 2020**           | Centre-pivot detection with transfer tests              | *Centre-pivot Mapping*                  | Sentinel-2 optical                          | U-Net (baseline)                              | U-Net + PCA vs. raw bands                    | Cross-site transfer (USA, Spain, South Africa)     |
| **Gargiulo et al. 2019**       | Rice classification using SAR                           | *Paddy-rice Detection / Classification* | Sentinel-1 SAR                              | U-Net, FPN, LinkNet (fine-tuned)              | Pre-train vs. fine-tune; VV/VH polarisations | Polarisation & training-strategy effects           |
| **Zhang et al. 2025**          | Agricultural-parcel extraction with prior knowledge     | *Field-boundary Segmentation*           | Gaofen-2 RGB (ultra-HR)                     | D-LinkNet + prior geographic knowledge        | D-LinkNet (plain)                            | With vs. without prior-knowledge injection         |
| **de Oliveira et al. 2020**    | Amazon deforestation mapping (data fusion)              | *Land-cover Mapping*                    | Sentinel + Landsat mosaics                  | Three custom CNNs                             | ResNet50, InceptionResNetV2…                 | Optimiser tests; effect of data fusion             |


## Main Results

| Aspect                         | Outcome                                                                                                                                                                                      |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pooled performance**         | **F<sub>1</sub> = 0.876** (95 % CI 0.766–0.938) across 104 experimental arms                                                                                                                 |
| **Heterogeneity**              | Very high (total *I*² ≈ 94 %; 73 % between‐study, 21 % within‐study)                                                                                                                         |
| **Prediction interval**        | 0.247 – 0.993 → real-world results can vary widely                                                                                                                                           |
| **Significant moderator**      | **Architecture** (p = 0.03): custom CNNs led, while “Other” designs lagged; U-Net, DeepLabV3+, LinkNet and PSPNet were statistically equivalent                                              |
| **Non-significant moderators** | Task type, data source (optical vs. SAR), spatial resolution                                                                                                                                 |
| **Publication bias**           | Funnel plot shows mild asymmetry, but Egger’s test NS (p = 0.67)                                                                                                                             |
| **Sensitivity**                | Leave-one-out analyses kept pooled F<sub>1</sub> in 0.84 – 0.89 range → findings robust                                                                                                      |
| **Key takeaway**               | High accuracy in controlled trials masks poor geographic transferability. Future gains hinge on tougher cross-site benchmarks, data-efficient training and reproducible reporting standards. |

---

## Citation

If you find this work useful, please cite:

```
Batista, M., Batista, B., Souza, V., & Souza, A. (2025).
Advances in Land Use and Land Cover Segmentation: A Meta‑Analytic Review of Artificial Intelligence‑Based Models.
```

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

*Last updated: July 2025*

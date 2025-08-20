# ParaGen-Dataset

## Project Structure

The structure of this project is shown below:

```
ParaGen-Dataset
├─ 📁collect
│  ├─ 📁collect_scripts    # scripts for checkpoint collection
│  │  ├─ 📁coding
│  │  │  ├─ 📄<model_name>_<dataset_name>_finetune.yaml
│  │  │  ├─ 📄<model_name>_<dataset_name>_pretrain.yaml
│  │  │  └─ ...
│  │  ├─ 📁common-sense-reasoning
│  │  ├─ 📁math
│  │  └─ 📁multimodal
│  ├─ 📁data
│  │  ├─ 📁coding
│  │  │  ├─ 📄<dataset_name>.json
│  │  │  └─ ...
|  |  ├─ 📁common-sense-reasoning
│  │  ├─ 📁math
│  │  ├─ 📁multimodal
│  │  └─ 📄dataset_info.json
│  ├─ 📁models    # saved models
│  └─ 📁utils     # utilities for collection
│     ├─ 📄download_csr_models.sh
│     ├─ 📄train_with_rank.sh
│     └─ ... other utilities
├─ 📁saves     # saved checkpoints
|  ├─ 📁coding
|  |  └─ 📁<dataset_name>
|  |     ├─ 📁<model_name>_lora-rank_<rank>_finetune
|  |     └─ 📁<model_name>_lora-rank_<rank>_pretrain
|  ├─ 📁common-sense-reasoning
|  ├─ 📁math
|  └─ 📁multimodal
├─ 📄.gitignore
├─ 📄LICENSE
└─ 📄README.md
```

## Collect a new pair

### Register the dataset

1. Place your dataset file in the corresponding task directory, ensuring it is in the correct `.json` format. For example, the ARC-c dataset, which is intended for common-sense reasoning, should be placed in the `ParaGen-Dataset/collect/data/common-sense-reasoning/` directory.<br>
   _The available task categories are: common-sense reasoning, coding, math, and multimodal._

2. Register the dataset in `ParaGen-Dataset/collect/data/dataset_info.json`. Note that the `columns` key may vary between datasets.

   ```json
   <dataset_name>:
   {
        "file_name": "<dataset_name>.json",
        "columns": {
            "prompt":"prompt",
            "response":"response",
            "system":"system"
        },
   }
   ```

For more details on registering dataset files, refer to the [LLaMA Factory Documentation – Getting Started: Dataset Preparation](https://llamafactory.readthedocs.io/zh-cn/latest/getting_started/data_preparation.html).

### Download the model

There are three ways to download the model.

1. Download directly from huggingface<br>
   You can download the model you need from huggingface with the command below:
   ```bash
   huggingface-cli download <model_name> --local-dir ParaGen-Dataset/collect/models/<model_name>
   ```
2. Download manually from huggingface<br>
   Visit the [official site of huggingface](https://huggingface.co/) and search for the required model. Navigate to `<REPO_ID>` --> `Files and Versions` to view available files then download the necessary ones.
3. Download with from HF-Mirror<br>
   If you cannot access the official Hugging Face site or have an unstable connection, use the HF-Mirror instead.<br>
   Detailed instructions are available on the [HF-Mirror website](https://hf-mirror.com/).

### Checkpoint collection

1. Create script for pretraining
   Create a new file named `<your_model>_<your_dataset>_pretrain.yaml` under `ParaGen-Dataset/collect/collect_scripts/<your_task_category>`.  
   You do not have to follow this exact naming format — you may name the script however you prefer.  
   For details on what to include in the training script, see the [LLaMA Factory Documentation – Getting Started: Supervised Fine-tuning](https://llamafactory.readthedocs.io/en/latest/getting_started/sft.html).
2. Pretrain model
   Pretrain the model with the following command: <br>
   ```bash
   bash ../../utils/train_with_rank.sh <your_training_script>_pretrain.yaml <lora_rank>
   ```
   This command runs pretraining with rank=<lora*rank>.
   During execution, a temporary file named
   <your_model>*<your*dataset>\_pretrain_temp_rank*<lora_rank>.yaml
   will be created in the same directory as your original <your_training_script>\_pretrain.yaml.
   It will be automatically deleted after training completes.
3. As shown earlier, create a new file named `<your_model>_<your_dataset>_finetune.yaml` in the directory  
    `ParaGen-Dataset/collect/collect_scripts/<your_task_category>`.<br>
   Ensure that the value of the `resume_from_checkpoint` key is set to one of the checkpoints you collected during the pretraining process. This allows the model to continue training from the pretrained weights obtained earlier.
4. Collect checkpoints
   Similar to the pretraining process, finetune the model with the following command:

```bash
 bash ../../utils/train_with_rank.sh <your_training_script>_finetune.yaml <lora_rank>
```

### Customize prompt template (Optional)

Some models do not have a supported template registered in LLaMA-Factory.  
In such cases, you can add a custom template for your model.  
Add the following code to the `LLaMA-Factory/src/llamafactory/data/template.py` file:

```python
register_template(
    name="your_template_name",
    # detailed format configuration
)
```

You can then apply your customized template in future training scripts:

```yaml
### other training parameters in your_training_script.yaml
template: your_template_name
```

## Acknowledgements

We gratefully acknowledge the contribution of the [Drag-and-Drop LLMs](https://github.com/jerryliang24/Drag-and-Drop-LLMs) project, from which we sourced preprocessed dataset files and the `dataset_info.json` manifest used and modified in our project. The original data and framework were made available under the terms of the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0.html).

For scientific attribution and reproducibility, please cite the foundational work:

```bibtex
@misc{liang2025draganddropllmszeroshotprompttoweights,
      title={Drag-and-Drop LLMs: Zero-Shot Prompt-to-Weights},
      author={Zhiyuan Liang and Dongwen Tang and Yuhao Zhou and Xuanlei Zhao and Mingjia Shi and Wangbo Zhao and Zekai Li and Peihao Wang and Konstantin Schürholt and Damian Borth and Michael M. Bronstein and Yang You and Zhangyang Wang and Kai Wang},
      year={2025},
      eprint={2506.16406},
      archivePrefix={arXiv},
      primaryClass={cs.LG},
      url={https://arxiv.org/abs/2506.16406},
}
```

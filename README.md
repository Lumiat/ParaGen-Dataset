# ParaGen-Dataset

## Project Structure

The structure of this project is shown below:

## Collect a new pair

### Register the dataset

1. Place your dataset file in the dir of corresponding task with the correct form in `.json` format. For example, since ARC-c dataset is for common-sense-reasoning, it should be put under path `ParaGen-Dataset/collect/data/common-sense-reasoning/`.<br>
   _For tasks categories, we have common-sense-reasoning, coding, math and multimodel_

2. Register the dataset in `ParaGen-Dataset/collect/data/dataset_info.json`. For the record, the key `columns` might varies between datasets.
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
   For more information about the registration of dataset files, please refer to: [LLaMA Factory Documentation-Getting Started-Dataset Preparation](https://llamafactory.readthedocs.io/zh-cn/latest/getting_started/data_preparation.html)

### Download the model

There are three ways to download the model.

1. Download directly from huggingface<br>
   You can download the model you need from huggingface with the command below:
   ```bash
   huggingface-cli download <model_name> --local-dir ParaGen-Dataset/collect/models/<model_name>
   ```
2. Download manually from huggingface<br>
   Go to the [official site of huggingface](https://huggingface.co/) and search for the model you need. Then see all the model files by: `<REPO_ID>` --> `Files and Versions` and download those necessary.
3. Download with from HF-Mirror<br>
   If you can't access the official site of huggingface or your connection is unstable, you may switch to the mirror of HF-Mirror.<br>
   The guidelines for model download is on [HF-Mirror](https://hf-mirror.com/).

### Checkpoint collection

1. Create script for pretraining
   Create a new file `<your_model>_<your_dataset>_pretrain.yaml` under path `ParaGen-Dataset/collect/collect_scripts/<your_task_catagory>`. It's not necessary to name the training script in the format above, your can name it anything you want.<br>
   You can refer to [LLaMA-Factory Documentation-Getting Started-Supervised Fine-tuning](https://llamafactory.readthedocs.io/en/latest/getting_started/sft.html) for more information of the content to be included in the training script.
2. Pretrain model
   Pretrain the model with the following command.
   ```bash
   bash ../../utils/train_with_rank.sh <your_training_script>_pretrain.yaml <lora_rank>
   ```
   This command will pretrain the model with `rank=<lora_rank>` . A temporary file named `<your_model>_<your_dataset>_pretrain_temp_rank_<lora_rank>.yaml` will be created in the same dir that your original `<your_training_script>_pretrain.yaml` is in. It will be deleted after the training process automatically.
3. Create script for finetuning
   As shown before, Create a new file `<your_model>_<your_dataset>_finetune.yaml` under path `ParaGen-Dataset/collect/collect_scripts/<your_task_catagory>`.
   Make sure the value for key `resume_from_checkpoint` is one of the existing checkpoints you just collected from the pretraining process. This will allow the model to finetune the pretrained model from the pretraining process before.
4. Collect checkpoints
   Similar to the pretraining process, finetune the model with the following command:
   ```bash
    bash ../../utils/train_with_rank.sh <your_training_script>_finetune.yaml <lora_rank>
   ```
   It's also okay to collect in batch using a script.

### Customize prompt template (Optional)

Some models don't have supported template registered in LLaMA-Factory, therefore there's a chance for you to add the customized template for your model.<br>
The following code should be added in file `LLaMA-Factory/src/llamafactory/data/template.py`:

```python
register_template(
    name="your_template_name",
    # detailed format configuration
)
```

Then you can use your customized template in training script in the furture:

```yaml
### other training parameters in your_training_script.yaml
template: your_template_name
```

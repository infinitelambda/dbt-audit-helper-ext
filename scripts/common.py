import operator
import os
import sys


def get_models(directory: str = "models/03_mart", name=None) -> dict:
    """
    Collect list of models (dict[model_name, model_dir]) in the mart folder

    Returns:
        List[dict]: {model_name: ..., model_dir: ...}
    """
    models = []
    for dirpath, _, filenames in os.walk(directory):
        for file in filenames:
            if file.endswith(".sql"):
                filename = os.path.splitext(file)[0]
                if name is not None and filename != name:
                    continue
                models.append(
                    dict(
                        model_name=filename,
                        model_dir=dirpath,
                    )
                )
    return sorted(models, key=operator.itemgetter("model_name"))


def get_args() -> tuple[str, str]:
    """Extract the CLI arguments"""
    mart_dir = "models/03_mart"
    model_name = None
    if len(sys.argv) < 2:
        print(f"💁 Assumming the mart directory is [{mart_dir}]")
    else:
        mart_dir = sys.argv[1]
        if len(sys.argv) > 2:
            model_name = sys.argv[2]

    return (mart_dir, model_name)

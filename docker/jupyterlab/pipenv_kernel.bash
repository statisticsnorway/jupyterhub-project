#!/usr/bin/env bash

# *** CREATE ***
if [ "$1" == "create" ]; then
  if [ $# -ne 3 ]
    then
      echo "This command creates a jupyterlab kernel with a given name, and initializes a 'pipenv' virtual environment that will track (un)installs for this project."
      echo "Exactly 2 arguments must be supplied to 'pipenv-kernel create'. The first argument is the name of the new kernel. The second argument must be the path to the existing kernel that you wish to base the new kernel on, ending with the folder named after the kernel."
      echo "Current folder path: "
      pwd
      jupyter kernelspec list
      exit 1
  fi

  echo "Starting kernel creation with these parameters:"
  export NEW_KERNEL_NAME=$2
  echo "- New kernel name: $NEW_KERNEL_NAME"
  export NTKP="$NEW_KERNEL_NAME-template_kernel.path"
  if test -f "$NTKP"; then
    TEMPLATE_KERNEL_PATH=$(cat "$NTKP")
    export TEMPLATE_KERNEL_PATH
  else
    TEMPLATE_KERNEL_PATH=$3/kernel.json
    export TEMPLATE_KERNEL_PATH
    echo "$TEMPLATE_KERNEL_PATH" > "$NTKP"
  fi
  echo "- Template kernel path: $TEMPLATE_KERNEL_PATH"
  NEW_KERNEL_PATH=/home/jovyan/.local/share/jupyter/kernels/$NEW_KERNEL_NAME/kernel.json
  export NEW_KERNEL_PATH
  echo "- New kernel target path: $NEW_KERNEL_PATH"

  echo "Installing prerequisites..."
  pip install pipenv
  echo "Creating/Activating pipenv virtual environment for current directory/project, and installing ipykernel..."
  pipenv install
  pipenv run pip install ipykernel
  echo "In the newly created pipenv associated with the current directory, create new kernel with name '$NEW_KERNEL_NAME'..."
  pipenv run python -m ipykernel install --user --name="$NEW_KERNEL_NAME"

  # Hent og rediger ENV variabler fra eksisterende template kernel
  LOCAL_KERNEL_COPY_FILENAME="$NEW_KERNEL_NAME-kernel-copy.json"
  export LOCAL_KERNEL_COPY_FILENAME
  NEW_PYPATH="$(pipenv --venv)"
  export NEW_PYPATH
  jq '.env.PYTHONPATH = "'"$NEW_PYPATH"':" + .env.PYTHONPATH' "$TEMPLATE_KERNEL_PATH" > tmp.$$.json && mv tmp.$$.json "$LOCAL_KERNEL_COPY_FILENAME"
  # Add .env dictionary fra "kernel.json" inn i /home/jovyan/.local/share/jupyter/kernels/<kernel-name>/kernel.json
  KERNEL_ENV=$(jq ".env" "$LOCAL_KERNEL_COPY_FILENAME")
  export KERNEL_ENV
  jq ".env = $KERNEL_ENV" "$NEW_KERNEL_PATH" > "$LOCAL_KERNEL_COPY_FILENAME" && cp "$LOCAL_KERNEL_COPY_FILENAME" "$NEW_KERNEL_PATH"
  echo "NEW KERNEL.JSON:"
  cat "$NEW_KERNEL_PATH"
  exit 0

# *** ACTIVATE ***
elif [ "$1" == "activate" ]; then
  if [ $# -ne 2 ]; then
    echo "When activating a pipenv-kernel, you must provide the name of the kernel as an argument: 'pipenv-kernel activate <kernel-name>'. Use 'jupyter kernelspec list' to get a list of all registered kernels. "
    exit 1
  fi

  pip install pipenv

  if test -f "Pipenv" $$ test -f "Pipenv.lock"; then
    echo "Pipenv and Pipenv.lock files are present in the current directory. Installing..."
    pipenv install
  else
    echo "Something is wrong: Pipenv and Pipenv.lock are not both present in this folder. Run 'pipenv install' to initialize them both, or run 'pipenv-kernel create <kernel-name> <template-path>' to generate a new pipenv AND new kernel for this folder."
    exit 1
  fi

  export KERNEL_NAME=$2
  KERNEL_PATH="/home/jovyan/.local/share/jupyter/kernels/$KERNEL_NAME/kernel.json"
  export KERNEL_PATH
  if test -f "$KERNEL_PATH"; then
    echo "kernel.json already present at: '$KERNEL_PATH'. No activation required."
    exit 0
  fi

  LOCAL_KERNEL_COPY_FILENAME="$KERNEL_NAME-kernel-copy.json"
  export LOCAL_KERNEL_COPY_FILENAME

  echo "Kernel not present at $KERNEL_PATH! Looking for auto-generated copy of 'kernel.json' in current folder. The file should be called '$LOCAL_KERNEL_COPY_FILENAME'."

  if test -f "$LOCAL_KERNEL_COPY_FILENAME"; then
    echo "Found a '$LOCAL_KERNEL_COPY_FILENAME' in this folder."
    pipenv run python -m ipykernel install --user --name="$KERNEL_NAME"
    echo "Copying contents of '$LOCAL_KERNEL_COPY_FILENAME' into '$KERNEL_PATH'"
    cp "$LOCAL_KERNEL_COPY_FILENAME" "$KERNEL_PATH"
    exit 0
  else
    export NTKP="$KERNEL_NAME-template_kernel.path"
    echo "No kernel definition copy present at '$LOCAL_KERNEL_COPY_FILENAME'. Looking for file containing path to template kernel in current folder. The file should be called '$NTKP'."
    if test -f "$NTKP"; then
      TEMPLATE_KERNEL_PATH=$(cat "$NTKP")
      export TEMPLATE_KERNEL_PATH
      echo "Found! Path to template kernel: "
      echo "$TEMPLATE_KERNEL_PATH"
      if test -f "$TEMPLATE_KERNEL_PATH"; then
        echo "Found a file at template kernel path. cat:"
        cat "$TEMPLATE_KERNEL_PATH"
        echo "If you want to create a kernel called '$KERNEL_NAME' with this template, run this command: 'pipenv-kernel create $KERNEL_NAME $TEMPLATE_KERNEL_PATH' "
      else
        echo "No file found at the given kernel template path."
      fi
    else
      echo "Could not find a file '$NTKP' in this folder containing the path to the template kernel for '$KERNEL_NAME'. Looks like there is no trace of a kernel with the name '$KERNEL_NAME'. You can create it using the command 'pipenv-kernel create $KERNEL_NAME <template-kernel>'. A list of possible template kernel paths can be found with the command 'jupyter kernelspec list'."
    fi
    exit 1
  fi

# *** DELETE-ALL ***
elif [ "$1" == "delete-all" ]; then
  if [ $# -ne 2 ]
    then
      echo "This command requires the name of the kernel you want deleted to be passed as an argument."
      echo "This command will only work if you run it from a folder that has a pipenv and kernel generated for it using the 'pipenv-kernel create' command."
      echo "To only delete the kernel, but not the pipenv, run 'jupyter kernelspec uninstall <kernel-name>'."
      echo "Current folder full path: "
      pwd
      echo "Path to pipenv of current folder: "
      pipenv --venv
      jupyter kernelspec list
    exit 1
  fi

  KERNEL_NAME=$2
  export KERNEL_NAME
  echo "WARNING: You are about to delete a kernel named '$KERNEL_NAME' and the pipenv virtual environment related to this folder, including Pipfile(.lock) which tracks project dependencies. This tool will function to delete a pipenv and kernel generated for this folder using the 'pipenv-kernel' command."
  echo "Do you REALLY wish to DELETE the kernel named '$KERNEL_NAME', this virtual environment, and ALL associated files in this folder? (Yes/No)"
  read yn
  if [[ "$yn" =~ "Yes" ]]; then
    PIPENV_PATH="$(pipenv --venv)"
    echo "Path to pipenv virtual environment associated with current folder: $PIPENV_PATH"
    rm -rf "$PIPENV_PATH"
    echo "Virtual environment deleted"
    echo "Removing pipfile and lockfile from this folder."
    rm Pipfile
    rm Pipfile.lock
    pipenv-kernel delete-kernel "$KERNEL_NAME"
    exit 0
  else
    exit 1
  fi

# *** DELETE-KERNEL ***
elif [ "$1" == "delete-kernel" ]; then
  if [ $# -ne 2 ]; then
    echo "This command deletes a kernel (only kernel, not the pipenv) created using the 'pipenv-kernel' command."
    echo "Kernel name must be given as an argument: 'pipenv-kernel delete-kernel <kernel-name>'"
    exit 1
  fi

  KERNEL_NAME=$2
  echo "Attempting to uninstall kernel named '$KERNEL_NAME' using 'jupyter kernelspec uninstall': "
  jupyter kernelspec uninstall "$KERNEL_NAME"
  echo "Removing kernel-creation related files from this folder."
  LOCAL_KERNEL_COPY_FILENAME="$KERNEL_NAME-kernel-copy.json"
  rm "$LOCAL_KERNEL_COPY_FILENAME"
  NTKP="$KERNEL_NAME-template_kernel.path"
  rm "$NTKP"

# *** DELETE-PIPENV ***
elif [ "$1" == "delete-pipenv" ]; then
  PIPENV_PATH="$(pipenv --venv)"
  echo "Path to pipenv virtual environment associated with current folder: $PIPENV_PATH"
  rm -rf "$PIPENV_PATH"
  echo "Virtual environment deleted"
  if [ "$2" == "--hard" ]; then
    echo "'--hard' deleting pipenv: Removing Pipfile(.lock) from current folder"
    rm Pipfile
    rm Pipfile.lock
  fi
  exit 0
else
  echo "'pipenv-kernel' takes argument 'create', 'activate' 'delete-all', 'delete-kernel', 'delete-pipenv'. Try them without further arguments for more info about what they do."
  exit 1
fi

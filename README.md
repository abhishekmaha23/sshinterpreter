# SSH interpreter layer for Docker images
TLDR - Adds an SSH Daemon layer to lib-based Docker images that allows them to be used as secure Pycharm SSH interpreters (remote execution)

Pycharm offers an SSH interpreter option that allows a remote system to be used for execution of Python code.
There are many Docker images freely available that package up code libraries and environments, which makes it convenient in many situations to set up virtual environments with compatible system libraries.

Most Docker images do not provide SSH access for security reasons, or because they aren't really required.
However, bridging Pycharm with Docker allows for a much less-complicated and time-consuming setting-up process.

This project includes a simple way to generate a Docker image that adds an SSH-layer to common Docker images, so that it is possible to easily link them with Pycharm and start executing code.

The SSH server is installed on top of the existing image, and the entry-point is set to start as a non-root user (pycharmuser) such that there is no unathorized file access.

Ubuntu has the most drivers and support, and thus, this project is targeted towards Debian systems, but it should not be difficult to customize for other Linux OSes.

Building using the Dockerfile
----
No addition is required to the usual format
docker build -t sshinterpreter:custom-tag .

Initializing a container
----
The port that the SSH server runs at is 2022. In the following examples, it is mapped to 8889 on localhost, but modify as needed.
The files that Pycharm must execute must be mapped in two places - one in the following command, and one in the next section.
The mapping here is the usual Docker volume mapping.

To obtain a simple execution environment, the following section of code should be enough

    docker run -it -d -u pycharmuser -p 8889:2022 -v /path/to/local_pycharm_project:/home/pycharmuser/shared sshinterpreter:custom-tag

With GPU access (nvidia-container-toolkit must be installed)

    docker run -it -d -u pycharmuser --gpus all -p 8889:2022 -v /path/to/local_pycharm_project:/home/pycharmuser/shared sshinterpreter:custom-tag

If rendering or any kind of display is necessary, the local X Server must either drop the access level control (through 'xhost +'), which is non-ideal.
Instead, a solution through mapping the X socket window (Credit: https://stackoverflow.com/a/43016704)

With GPU access and remote display

    docker run -it -d -u pycharmuser --gpus all -e DISPLAY -p 8889:2022 -v /path/to/local_pycharm_project:/home/pycharmuser/shared -v /tmp/.X11-unix:/tmp/.X11-unix -v /etc/localtime:/etc/localtime:ro sshinterpreter:custom-tag

Modifying the container further
----
You can then SSH directly into the container, obtain a bash shell and install any further packages specifically for the user pycharmuser using 

    pip install --user [packagenames]

Connecting to Pycharm as an SSH Interpreter
----
Add an SSH interpreter to Pycharm (started with a custom non-root user) using the following settings:
+ URL: 127.0.0.1
+ Port: 8889 (or the port you exposed for the container)
+ Username: pycharmuser
+ Password: pypass

Leave the interpreter as-is, since the python binary inside the container is most likely system-wide.
Depending on the image, the location might vary though (usually between /usr/bin/python or /usr/local/bin/python)

When asked for folder mapping, edit the target part of the mapping from the temp folder to '/home/pycharmuser/shared'

Deselect the option to automatically copy project files to the server, since the run command automatically should map the required volume.
(This method makes the code run directly on the shared files, and edits need not be sent by sftp each time)

Known bugs
----
- Bug - Any rendering with Pyglet/OpenGL results in a failure to create GL context. OpenAI gym environment rendering suffers from this problem.
- Bug - Since an SSH session starts up a new bash shell, the env variable DISPLAY is lost. It is however, possible to manually set the DISPLAY variable to :0 or so, either through code or directly in the shell. (One fix would be to copy it to a bashrc for the user pycharmuser)

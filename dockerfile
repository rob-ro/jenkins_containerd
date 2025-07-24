FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg

RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

RUN apt-get update && \
    apt-get install -y kubectl=1.28.0-00 && \
    apt-mark hold kubectl  # 防止意外升级

RUN kubectl version --client --short

RUN wget https://github.com/containerd/nerdctl/releases/download/v1.7.6/nerdctl-1.7.6-linux-amd64.tar.gz
RUN mkdir -p /usr/local/containerd/bin/ && tar -zxvf nerdctl-1.7.6-linux-amd64.tar.gz nerdctl && mv nerdctl /usr/local/containerd/bin/
RUN ln -s /usr/local/containerd/bin/nerdctl /usr/local/bin/nerdctl

RUN wget https://github.com/moby/buildkit/releases/download/v0.13.2/buildkit-v0.13.2.linux-amd64.tar.gz
RUN tar -zxvf buildkit-v0.13.2.linux-amd64.tar.gz -C /usr/local/containerd/
RUN ln -s /usr/local/containerd/bin/buildkitd /usr/local/bin/buildkitdIn
RUN ln -s /usr/local/containerd/bin/buildctl /usr/local/bin/buildctl

RUN sh -c 'cat > /etc/systemd/system/buildkit.service << "EOF" \
[Unit] \
Description=BuildKit \
Documentation=https://github.com/moby/buildkit \
[Service] \
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true \
[Install] \
WantedBy=multi-user.target \
EOF'
RUN systemctl daemon-reload
RUN systemctl enable buildkit --now
RUN systemctl status buildkit.service

USER jenkins

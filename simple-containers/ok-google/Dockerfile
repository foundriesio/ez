FROM foundriesio/minideb:stretch

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN install_packages build-essential python3-dev libffi-dev python3-pip \
                     alsa-utils ffmpeg swig libportaudio2 pulseaudio pavucontrol portaudio19-dev libpulse-dev

RUN pip3 install --upgrade wheel setuptools
RUN pip3 install --upgrade google-assistant-grpc google-cloud-speech google-auth-oauthlib pyasn1 grpcio click

# Install google assistent sdk / sample apps
RUN pip3 install --upgrade google-assistant-sdk[samples] google-assistant-library

COPY start.sh /
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
CMD ["bash", "-c", "googlesamples-assistant-hotword --project_id ${PROJECT_ID}  --device_model_id ${MODEL_ID}"]

"use client";

import { useEffect, useRef } from "react";
import * as shaka from "shaka-player/dist/shaka-player.compiled";

export type VideoPlayerProps = {
  url: string;
  poster: string;
};

export function VideoPlayer({ url, poster }: VideoPlayerProps) {
  const videoNodeRef = useRef<HTMLVideoElement>(null);
  const playerRef = useRef<shaka.Player>();

  useEffect(() => {
    if (!shaka.Player.isBrowserSupported()) {
      console.error("O navegador não suporta o Shaka Player.");
      return;
    }

    if (!playerRef.current) {
      shaka.polyfill.installAll();
      const player = new shaka.Player(videoNodeRef.current!);
      playerRef.current = player;

      player.configure({
        drm: {
          servers: {
            'com.widevine.alpha': 'URL_DO_SERVIDOR_WIDEVINE',
          },
        },
        streaming: {
          preferredVideoCodecs: ['vp9', 'avc1.42E01E'],
        },
      });

      player.attach(videoNodeRef.current!).then(() => {
        console.log("The player has been attached");
        player.load(url).then(() => {
          console.log("The video has now been loaded!");
        }).catch((error) => {
          console.error("Erro ao carregar o vídeo:", error);
        });
      });

      player.addEventListener("error", (event) => {
        const shakaError = event as unknown as shaka.util.Error;
        console.error(
          `Erro no Shaka Player: Código ${shakaError.code}, Detalhes: ${shakaError.data}`
        );
      });
    }

    return () => {
      if (playerRef.current) {
        playerRef.current.destroy().then(() => console.log("Player destroyed"));
      }
    };
  }, [url]);

  return (
    <video
      ref={videoNodeRef}
      className="w-full h-full"
      controls
      autoPlay
      poster={poster}
    />
  );
}

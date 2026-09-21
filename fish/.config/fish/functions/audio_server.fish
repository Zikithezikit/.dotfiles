function audio_server --wraps='as-cmd --bind=10.100.102.20 --encoding=f32 --channels=2 --sample-rate=48000' --description 'alias audio_server=as-cmd --bind=10.100.102.20 --encoding=f32 --channels=2 --sample-rate=48000'
  as-cmd --bind=10.100.102.20 --encoding=f32 --channels=2 --sample-rate=48000 $argv
        
end

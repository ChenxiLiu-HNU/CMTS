export CUDA_VISIBLE_DEVICES=$3

all_models=("Transformer")
start_index=$1
end_index=$2
root_paths=("./data/combined/Agriculture")
data_paths=("Agriculture_search_200906.csv")
models=("${all_models[@]:$start_index:$end_index-$start_index+1}")
d_model=(16 32 64)
e_layers=(1 2 3)
d_layers=(0)
revin=1
text_len=1
text_ts=0
text_col=("search_fact_lb36" "search_preds_lb36" "ts")
text_random=0
text_random_order=0
text_emb=32
length=${#root_paths[@]}
seq_length=8
pred_lengths=(8)
seeds=(2024)
use_fullmodel=1
llm_model=GPT2
llm_from_stratch=0
fusion_method=concat
# prompt_weight=(0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9)
prompt_weight=(1)
history_weight=0
connector_dropout=(0.2)
learning_rate=(1e-3 5e-4 1e-4)
train_epochs=(30 50)


for seed in "${seeds[@]}"
do
  for model_name in "${models[@]}"
  do
    for ((i=0; i<$length; i++))
    do
      for pred_len in "${pred_lengths[@]}"
      do
        root_path=${root_paths[$i]}
        data_path=${data_paths[$i]}
        model_id=$(basename ${root_path})

        echo "Running model $model_name with root $root_path, data $data_path, and pred_len $pred_len"

        for pw in "${prompt_weight[@]}"
        do
          for tcol in "${text_col[@]}"
          do
            for dm in "${d_model[@]}"
            do
              for el in "${e_layers[@]}"
              do
                for dl in "${d_layers[@]}"
                do
                  for cdrop in "${connector_dropout[@]}"
                  do
                    for lr in "${learning_rate[@]}"
                    do
                      for te in "${train_epochs[@]}"
                      do
                        python -u run.py \
                          --task_name long_term_forecast \
                          --is_training 1 \
                          --root_path $root_path \
                          --data_path $data_path \
                          --model_id ${model_id}_${seed}_8_${pred_len}_text${text_len}_fm${fusion_method}_pw${pw} \
                          --model $model_name \
                          --data custom \
                          --features M \
                          --seq_len $seq_length \
                          --label_len 0 \
                          --pred_len $pred_len \
                          --des 'Exp' \
                          --seed $seed \
                          --type_tag "#F#" \
                          --d_model $dm \
                          --e_layers $el \
                          --d_layers $dl \
                          --rev_in $revin \
                          --text_emb $text_emb \
                          --text_len $text_len \
                          --text_ts $text_ts \
                          --text_col $tcol \
                          --text_random $text_random \
                          --text_random_order $text_random_order \
                          --fusion_method $fusion_method \
                          --prompt_weight $pw \
                          --history_weight $history_weight \
                          --connector_dropout $cdrop \
                          --pool_type "last" \
                          --save_name results/${model_id}_${seed}_8_${pred_len}_text${text_len}_fm${fusion_method}_pw${pw}_fullLLM${use_fullmodel} \
                          --llm_model $llm_model \
                          --llm_from_stratch $llm_from_stratch \
                          --use_fullmodel $use_fullmodel \
                          --learning_rate $lr \
                          --train_epochs $te \
                          2>&1 | tee -a logs/${model_id}_${seed}_8_${pred_len}_text${text_len}_fm${fusion_method}_pw${pw}_fullLLM${use_fullmodel}.log
                      done
                    done
                  done
                done
              done
            done
          done
        done
      done
    done
  done
done

from cProfile import label
import pandas as pd
from matplotlib import pyplot as plt

def strong_scalability():
    data = pd.read_csv('results/strong_scalability.csv', index_col=False)
    timing = data['TIME']
    speed_up = []
    for time in timing:
        speed_up.append(timing[0]/time)

    data['SPEED_UP'] = speed_up
    data.to_csv('results/strong_scalability.csv', index=False)

    plt.figure(figsize=(16,10))
    plt.title('Strong Scalability')
    plt.xlabel('Numero Processori')
    plt.ylabel('Speed Up')
    plt.plot(data['PROCESSES'][1:], data['SPEED_UP'][1:], label='Ottenuto')
    plt.plot(data['PROCESSES'][1:], data['PROCESSES'][1:], label='Ideale', linestyle='--')
    plt.legend(title='Speed Up')
    plt.grid(True)
    plt.xlim([1,25])
    plt.ylim([1,24])    
    plt.xticks(data['PROCESSES'][1:])
    plt.savefig('results/strong_scalability.png')


def weak_scalability():
    data = pd.read_csv('results/weak_scalability.csv')

    plt.figure(figsize=(16,10))
    plt.title('Weak Scalability')
    plt.xlabel('Numero Processori')
    plt.ylabel('Tempo in Secondi')
    plt.plot(data['PROCESSES'], data['TIME'], label='Ottenuto')
    ideale = [data['TIME'][0] for x in range(0,24)]
    plt.plot(data['PROCESSES'], ideale, label='Ideale', linestyle='--')
    plt.legend()
    plt.grid(True)
    plt.xticks(data['PROCESSES'])
    plt.savefig('results/weak_scalability.png')


if __name__ == '__main__':
    plt.style.use('fivethirtyeight')
    strong_scalability()
    weak_scalability()

    plt.show()

#include <iostream>
#include <vector>
#include <cmath>
#include <iomanip>
#include <string>
#include <algorithm>

using namespace std;

const int WINDOW_SIZE_5 = 5;
const int WINDOW_SIZE_10 = 10;


//generate the y vector
vector<double> generateY(int N) {
    vector<double> y(N);
    for (int i = 0; i < N; i++) {
        double x;
        if (N == 1) {
            x = 0.0;  // 当只有一个点时，设为0
        } else {
            x = -5.0 + 10.0 * static_cast<double>(i) / static_cast<double>(N - 1);
        }
        y[i] = cos(x);
    }
    return y;
}



class MovingAverage{

    private:
    // dealing index with different boundary conditions
    int get_index_in_restricted_condition(int index, int n){
        if(index >= n) return -1;
        return index;
    }
    int get_index_in_cyclic_condition(int index, int n){
        int res = index % n;
        if(res < 0) res += n;
        return res;
    }

    int get_index_in_padding_condition(int index, int n){
        if(index < 0) return 0;
        if(index >= n) return n - 1;
        return index;
    }



    public:


    string computation_type;//forward, backward, centered
    string boundary_handling;//restricted, cyclic, padding
    vector<double> y;
    vector<double> ma5;
    vector<double> ma10;
    vector<double> compute_moving_average(int window_size){
        int n = this->y.size();//the size of the y vector

        // deal with the special case
        if(n == 0 || window_size <= 0) return vector<double>();
        vector<double> res(n, 0.0);
        for(int i = 0; i < n; i++){

            // deal with the different boundary conditions
            int L, R;
            if(this->computation_type == "backward"){
                L = i - (window_size - 1);
                R = i;
            }else if(this->computation_type == "centered"){
                int half = (window_size - 1) / 2;
                L = i - half;
                R = i + half;
            }else{
                L = i;
                R = i + (window_size - 1);
            }

            //sum the elements in the window
            double sum = 0.0;
            int cnt = 0;

            for(int j = L; j <= R; j++){
                if (this->boundary_handling == "restricted"){
                    if(j >= 0 && j < n){
                        sum += this->y[j];
                        cnt++;
                    }
                }else if(this->boundary_handling == "cyclic"){
                    sum += this->y[get_index_in_cyclic_condition(j, n)];
                    cnt++;
                }else if(this->boundary_handling == "padding"){
                    sum += this->y[get_index_in_padding_condition(j, n)];
                    cnt++;
                }
            }

            // deal with the special case
            if(cnt == 0){
                res[i] = 0.0;
            }else{
                res[i] = sum / cnt;
            }

        }
        return res;
    }

};


int main(int argc, char* argv[]) {
    int N = 100;
    string computation_type = "forward";
    string boundary_handling = "restricted";
    
    // 解析命令行参数
    for (int i = 1; i < argc; i++) {
        string arg = argv[i];
        
        if (arg == "--forward") {
            computation_type = "forward";
        } else if (arg == "--backward") {
            computation_type = "backward";
        } else if (arg == "--centered") {
            computation_type = "centered";
        } else if (arg == "--restricted") {
            boundary_handling = "restricted";
        } else if (arg == "--cyclic") {
            boundary_handling = "cyclic";
        } else if (arg == "--padding") {
            boundary_handling = "padding";
        } else if (arg == "--help" || arg == "-h") {
            cout << "usage: you will have the options below";
            cout << "--forward,backward,centered";
            cout << "--restricted,cyclic,padding";
            cout << "--N, the number of data points";
            cout << "and if you type more than one options on computation type ot the boundary handling, the last one will be used";
            return 0;
        } else {
            // 检查是否是数字参数
            try {
                int temp_N = stoi(arg);
                if (temp_N > 0) {
                    N = temp_N;
                } else {
                    cout << "N must be a positive integer, got: \n";
                    return 1;
                }
            } catch (const invalid_argument&) {
                cout << "Unknown argument:  \n";
                cout << "Use --help for usage information.\n";
                return 1;
            } 
        }
    }
    
    vector<double> y = generateY(N);
    
    MovingAverage ma;
    // 设置类的成员变量
    ma.y = y;
    ma.computation_type = computation_type;
    ma.boundary_handling = boundary_handling;
    
    vector<double> ma5 = ma.compute_moving_average(WINDOW_SIZE_5);
    vector<double> ma10 = ma.compute_moving_average(WINDOW_SIZE_10);
    
    // 输出结果
    cout.setf(std::ios::fixed);
    cout << setprecision(6);
    cout << "Number of data points (N): " << N << "\n";
    cout << "Computation type: " << computation_type << "\n";
    cout << "Boundary handling: " << boundary_handling << "\n";
    cout << "Original data, MA5, MA10:\n";
    for (int i = 0; i < N; ++i) {
        cout << setw(12) << y[i]   << ' '
             << setw(12) << ma5[i] << ' '
             << setw(12) << ma10[i] << '\n';
    }
    
    return 0;
}

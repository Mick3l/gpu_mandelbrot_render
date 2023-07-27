#ifndef UNICODE
#define UNICODE
#endif


#include <GL/freeglut.h>
#include <conio.h>
#include <windows.h>

#include <chrono>
#include <iostream>
#include <thread>

#include "cuda.h"
#include "cuda_runtime.h"
#include "lib/direct2d.h"

#pragma comment(lib, "d2d1")

#define WINDOW_HEIGHT 720
#define WINDOW_WIDTH 720

struct Transformation {
    float scale;
    float shift_x;
    float shift_y;
};

UINT8* PixelArray;
Transformation transformation = {1.0f, 0.0f, 0.0f};
RECT ClientRect;
gr::Direct2d graphics;
const int a = 0x41;
const int d = 0x44;
const int s = 0x53;
const int w = 0x57;

__device__ int Mandelbrot(float Re, float Im, float accuracy) {
    float temp_Re = Re;
    float temp_Im = Im;
    for (int i = 0; i < 10000 * accuracy + 1000; ++i) {
        float temp = temp_Re * temp_Re - temp_Im * temp_Im + Re;
        temp_Im = 2 * temp_Re * temp_Im + Im;
        temp_Re = temp;
        if (temp_Re * temp_Re + temp_Im * temp_Im > 4.0f) {
            return 0;
        }
    }
    return 1;
}

__global__ void GetPicture(UINT8* colors, int width, int height, Transformation transformation) {
    unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
    float x = idx % width;
    float y = idx / width;
    idx *= 4;
    if (idx < width * height * 4) {
        float Re = (2.f * x - width) * transformation.scale / width + transformation.shift_x;
        float Im = (2.f * y - height) * transformation.scale / height + transformation.shift_y;
        float accuracy = log(transformation.scale) / log(0.5);
        accuracy *= accuracy;
        if (Mandelbrot(Re, Im, accuracy)) {
            colors[idx] = 0;
            colors[idx + 1] = 0;
            colors[idx + 2] = 255;
            colors[idx + 3] = 255;
        } else {
            colors[idx] = 0;
            colors[idx + 1] = 0;
            colors[idx + 2] = 0;
            colors[idx + 3] = 255;
        }
    }
}

void PrintMandelbrot(UINT8* dest, RECT client_rect) {
    int width = client_rect.right - client_rect.left;
    int height = client_rect.bottom - client_rect.top;
    int N = width * height;
    cudaDeviceProp prop;
    cudaGetDeviceProperties_v2(&prop, 0);
    int L = prop.maxThreadsPerBlock;

    UINT8* cuda_color_array;
    cudaMalloc(&cuda_color_array, N * 4);

    GetPicture<<<(N + L - 1) / L, L>>>(cuda_color_array, width, height, transformation);
    cudaMemcpy(dest, cuda_color_array, N * 4, cudaMemcpyDeviceToHost);
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow) {
    // Register the window class.
    const wchar_t CLASS_NAME[] = L"Sample Window Class";

    WNDCLASS wc = {};

    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;

    RegisterClass(&wc);

    // Create the window.

    HWND hwnd = CreateWindowEx(
            0,                  // Optional window styles.
            CLASS_NAME,         // Window class
            L"Mandelbrot",      // Window text
            WS_OVERLAPPEDWINDOW,// Window style

            // Size and position
            CW_USEDEFAULT, CW_USEDEFAULT, WINDOW_WIDTH, WINDOW_HEIGHT,

            nullptr,  // Parent window
            nullptr,  // Menu
            hInstance,// Instance handle
            nullptr   // Additional application data
    );

    if (hwnd == nullptr) {

        return 0;
    }

    if (graphics.Initialize(hwnd)) {

        return 1;
    };

    ShowWindow(hwnd, nCmdShow);

    GetClientRect(hwnd, &ClientRect);
    PixelArray = new UINT8[(ClientRect.right - ClientRect.left) * (ClientRect.bottom - ClientRect.top) * 4];
    PrintMandelbrot(PixelArray, ClientRect);

    // Run the message loop.
    MSG msg = {};
    while (GetMessage(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        case WM_PAINT: {
            graphics.BeginDraw();
            D2D1_PIXEL_FORMAT format = {DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_IGNORE};
            D2D1_BITMAP_PROPERTIES prop = {format, 0, 0};
            ID2D1Bitmap* bitmap;
            PrintMandelbrot(PixelArray, ClientRect);
            HRESULT res = graphics.render_target->CreateBitmap(D2D1::SizeU(ClientRect.right - ClientRect.left, ClientRect.bottom - ClientRect.top),
                                                               PixelArray,
                                                               (ClientRect.right - ClientRect.left) * 4,
                                                               prop,
                                                               &bitmap);
            if (res == S_OK) {
                graphics.render_target->DrawBitmap(bitmap);
            }

            graphics.EndDraw();

            break;
        }

        case WM_KEYDOWN: {
            switch (LOWORD(wParam)) {
                case w: {
                    transformation.shift_y -= 1 * transformation.scale;
                    RedrawWindow(hwnd, &ClientRect, nullptr, RDW_INVALIDATE | RDW_UPDATENOW);
                    break;
                }

                case a: {
                    transformation.shift_x -= 1 * transformation.scale;
                    RedrawWindow(hwnd, &ClientRect, nullptr, RDW_INVALIDATE | RDW_UPDATENOW);
                    break;
                }

                case s: {
                    //todo why -+
                    transformation.shift_y += 1 * transformation.scale;
                    RedrawWindow(hwnd, &ClientRect, nullptr, RDW_INVALIDATE | RDW_UPDATENOW);
                    break;
                }

                case d: {
                    transformation.shift_x += 1 * transformation.scale;
                    RedrawWindow(hwnd, &ClientRect, nullptr, RDW_INVALIDATE | RDW_UPDATENOW);
                    break;
                }
            }

            break;
        }

        case WM_MOUSEWHEEL: {
            int delta = GET_WHEEL_DELTA_WPARAM(wParam);
            while (delta >= WHEEL_DELTA) {
                transformation.scale *= 0.5f;
                delta -= WHEEL_DELTA;
            }
            while (delta < 0) {
                transformation.scale /= 0.5f;
                delta += WHEEL_DELTA;
            }
            RedrawWindow(hwnd, &ClientRect, nullptr, RDW_INVALIDATE | RDW_UPDATENOW);

            break;
        }
        default: {

            break;
        }


            return 0;
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

//
//  PermissionRow.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 5/29/26.
//

import SwiftUI

struct PermissionRow: View {
    let permissionTitle: String
    let permissionDescription: String
    let systemImageName: String
    
    var body: some View {
        HStack{
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.blue50)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: systemImageName)
                        .font(.title2)
                        .foregroundStyle(Color.blue500))
                .padding(.trailing, 16)
            
            VStack{
                Text(permissionTitle)
                    .font(.body)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.gray900)
                    .padding(.bottom, 5)
                
                Text(permissionDescription)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.gray600)
                
            }
            
            
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .padding(.vertical, 18)
        .background{
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
            
        }
        
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 8)
        .padding(.horizontal, AppLayout.screenHorizontalPadding)

        
    }
}

struct PermissionRow_Previews: PreviewProvider {
    static var previews: some View {
        PermissionRow(
            permissionTitle: "마이크",
            permissionDescription: "회의 내용을 요약하고 다음 할 일을 정리해요.",
            systemImageName: "mic.fill"
        )
    }
}

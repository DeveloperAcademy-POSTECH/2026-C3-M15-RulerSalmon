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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue50)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: systemImageName)
                        .font(.title2)
                        .foregroundStyle(Color.blue500))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue100, lineWidth: 0.5)
                }
            
            VStack{
                Text(permissionTitle)
                    .font(.body)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.gray900)
                    .padding(.bottom, 2)
                
                Text(permissionDescription)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.gray600)
                
            }
            .padding(.leading, 8)
            
            
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background{
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray200, lineWidth: 1)
        }
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
